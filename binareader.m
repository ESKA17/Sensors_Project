function varargout = binareader(varargin)
% BINAREADER Peek into unknown binary file.
%
% Syntax:
%      BINAREADER, by itself, creates a new BINAREADER.
%
%      H = BINAREADER returns the handle to a new BINAREADER.
%
% Usage:
% A binareader is a little gui window that simplifies opening an unknown binary
% file and displaying the first few lines. With options to quickly change your
% guess as to what those unknown bits represent and what machine format was used
% to save the file, a small preview window updates with the parsed content. For
% convenience, there are buttons to save the data to the workspace or to a file
% once the right interpretation is found.

% Author:
% Naor Movshovitz
% University of California, Santa Cruz
% Apr. 2015

% Last Modified by GUIDE v2.5 03-Apr-2015 19:23:46

% Begin initialization code - DO NOT EDIT
gui_Singleton = 0;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @binareader_OpeningFcn, ...
                   'gui_OutputFcn',  @binareader_OutputFcn, ...
                   'gui_LayoutFcn',  @binareader_LayoutFcn, ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before binareader is made visible.
function binareader_OpeningFcn(hObject, ~, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to binareader (see VARARGIN)

% Choose default command line output for binareader
handles.output = hObject;

% Create a UD (user data) field in the handles structure
handles.UD.FID=nan;
handles.UD.fileFullPath='';
handles.UD.fileInfo=[];
handles.UD.expectedHeaderLines=0;
handles.UD.binaryDataVec=[];

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes binareader wait for user response (see UIRESUME)
% uiwait(handles.figure_mainGUI);


% --- Outputs from this function are returned to the command line.
function varargout = binareader_OutputFcn(~, ~, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in pushbutton_load.
function pushbutton_load_Callback(hObject, ~, handles) %#ok<*DEFNU>
% hObject    handle to pushbutton_load (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% file selection
[FileName,PathName]=uigetfile('*');

if ischar(FileName)
    % --First do some house cleaning
    % close already open file
    if ~isnan(handles.UD.FID)
        fclose(handles.UD.FID);
        handles.UD.FID=nan;
    end
    % make sure header and data previews are clear
    handles.UD.expectedHeaderLines=0;
    set(handles.edit_header_lines_counter,'String','0');
    set(handles.text_header_display,'String','');
    set(handles.text_preview,'String','');
    
    % -- Then deal with new file
    % display file info
    handles.UD.fileFullPath=[PathName,FileName];
    handles.UD.fileInfo=dir(handles.UD.fileFullPath);
    fileDispName=handles.UD.fileInfo.name;
    if length(fileDispName)>14
        fileDispName=[fileDispName(1:14) '...'];
    end
    S={['File: ',fileDispName];['Size: ',num2str(handles.UD.fileInfo.bytes/1e6,'%g'),' MB']};
    set(handles.text_file_info,'string',S);
    set(handles.pushbutton_load,'units','char')
    set(handles.text_file_info,'units','char')
    txtExt=get(handles.text_file_info,'extent');
    pos = get(handles.pushbutton_load,'position');
    yPos = 0.8*pos(2);
    pos = get(handles.text_file_info,'position');
    pos(2) = yPos;
    pos(3) = txtExt(3);
    pos(4) = txtExt(4);
    set(handles.text_file_info,'position',pos)
    set(handles.text_file_info,'visible','on');
    guidata(hObject,handles);
    
    % attempt to open file
    [fid msg]=fopen(handles.UD.fileFullPath,'r','n');
    if fid<0
        disp(msg);
    else
        handles.UD.FID=fid;
        guidata(hObject,handles);
    end
    
    % attempt to read binary data
    BinaryRead();
end


% --- Executes on button press in pushbutton_save_to_ws.
function pushbutton_save_to_ws_Callback(~, ~, handles)
% hObject    handle to pushbutton_save_to_ws (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if ~isempty(handles.UD.binaryDataVec)
    assignin('base','binary1',handles.UD.binaryDataVec);
end

% --- Executes on button press in pushbutton_save_as_txt.
function pushbutton_save_as_txt_Callback(~, ~, handles)
% hObject    handle to pushbutton_save_as_txt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if ~isempty(handles.UD.binaryDataVec)
    tmpStruct=handles.UD; %#ok<NASGU>
    save('binary1.txt','-ascii','-struct','tmpStruct','binaryDataVec');
end

% --- Executes on button press in pushbutton_save_as_mat.
function pushbutton_save_as_mat_Callback(~, ~, handles)
% hObject    handle to pushbutton_save_as_mat (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if ~isempty(handles.UD.binaryDataVec)
    tmpStruct=handles.UD; %#ok<NASGU>
    save('binary1','-struct','tmpStruct','binaryDataVec');
end

% --- Executes when user attempts to close figure_mainGUI.
function figure_mainGUI_CloseRequestFcn(hObject, ~, handles)
% hObject    handle to figure_mainGUI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

try
if ~isnan(handles.UD.FID)
    fclose(handles.UD.FID);
end
catch %#ok<CTCH>
    warning('fclose encountered an error, some files may remain open')
end
% Hint: delete(hObject) closes the figure
delete(hObject);


function edit_header_lines_counter_Callback(hObject, ~, handles)
% hObject    handle to edit_header_lines_counter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_header_lines_counter as text
%        str2double(get(hObject,'String')) returns contents of edit_header_lines_counter as a double
handles.UD.expectedHeaderLines=fix(str2double(get(hObject,'String')));
guidata(hObject,handles);
DisplayHeader();
BinaryRead();

% --- Executes during object creation, after setting all properties.
function edit_header_lines_counter_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_header_lines_counter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton_increment_header_lines_counter.
function pushbutton_increment_header_lines_counter_Callback(~, eventdata, handles)
% hObject    handle to pushbutton_increment_header_lines_counter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

hlc=fix(str2double(get(handles.edit_header_lines_counter,'String')));
set(handles.edit_header_lines_counter,'String',num2str(hlc+1));
edit_header_lines_counter_Callback(handles.edit_header_lines_counter,eventdata,handles);


% --- Executes on button press in pushbutton_decrement_header_lines_counter.
function pushbutton_decrement_header_lines_counter_Callback(~, eventdata, handles)
% hObject    handle to pushbutton_decrement_header_lines_counter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

hlc=fix(str2double(get(handles.edit_header_lines_counter,'String')));
if hlc>0
    set(handles.edit_header_lines_counter,'String',num2str(hlc-1));
    edit_header_lines_counter_Callback(handles.edit_header_lines_counter,eventdata,handles);
    if hlc==1 % so we just reduced to zero, also clear header preview
        set(handles.text_header_display,'String','');
    end
end


% --- Executes when selected object is changed in uipanel_read_as.
function uipanel_read_as_SelectionChangeFcn(~, ~, ~)
% hObject    handle to the selected object in uipanel_read_as 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)

BinaryRead();


% --- Executes when selected object is changed in uipanel_endiandness.
function uipanel_endiandness_SelectionChangeFcn(~, ~, ~)
% hObject    handle to the selected object in uipanel_endiandness 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)

BinaryRead();

%% --------------------- The non-callbacks ---------------------

function DisplayHeader()
% Attempt to read a few lines of text from loaded file and print in
% designated static text box

handles=guidata(gcbo);
if ~isnan(handles.UD.FID) && handles.UD.expectedHeaderLines>0
    frewind(handles.UD.FID);
    headStr={};
    for k=1:handles.UD.expectedHeaderLines
        headStr{k}=fgetl(handles.UD.FID); %#ok<AGROW>
    end
    set(handles.text_header_display,'String',headStr');
end

function BinaryRead()
% Attempt to read in binary data from file

handles=guidata(gcbo);
if isempty(handles.UD.fileInfo), return, end
if isempty(fopen(handles.UD.FID)), return, end

% position read head after header
fid=handles.UD.FID;
if handles.UD.expectedHeaderLines>0
    frewind(fid)
    l1 = fgetl(fid);
    frewind(fid)
    l2 = fgets(fid);
    nll = length(l2) - length(l1); % detect size of newline
    c = handles.text_header_display.String;
    skipBytes=nll*numel(c) + length([c{:}]);
else
    skipBytes=0;
end
if fseek(fid,skipBytes,'bof')<0
    warning off backtrace
    warning('Unable to seek in file, read aborted')
    warning on backtrace
    return
end

% determine machine format
machineformat='native'; %TODO: look into ieee-be.l64
if get(handles.radiobutton_big_endian,'value'), machineformat='ieee-be'; end
if get(handles.radiobutton_little_endian,'value'), machineformat='ieee-le'; end

% and read according to expected type
items = get(handles.menu_read_as,'String');
index_selected = get(handles.menu_read_as,'Value');
item_selected = items{index_selected};
readType = item_selected;

handles.UD.binaryDataVec=fread(fid,inf,['*',readType],0,machineformat);

% don't forget to save handles!
guidata(gcbo,handles);

% also, call ShowPreview
ShowPreview()

function ShowCall()
handles=guidata(gcbo);
if isempty(handles.UD.fileInfo), return, end
if isempty(fopen(handles.UD.FID)), return, end

fprintf('To load data do this:\n')
fprintf('fid = fopen(''%s'', ''r'', ''n''); %% open file\n',handles.UD.fileFullPath)

fid=handles.UD.FID;
if handles.UD.expectedHeaderLines>0
    frewind(fid)
    l1 = fgetl(fid);
    frewind(fid)
    l2 = fgets(fid);
    nll = length(l2) - length(l1); % detect size of newline
    c = handles.text_header_display.String;
    skipBytes=nll*numel(c) + length([c{:}]);
    fprintf('fseek(fid, %i, ''bof''); %% position read head after header\n',skipBytes)
end

machineformat='native'; %TODO: look into ieee-be.l64
if get(handles.radiobutton_big_endian,'value'), machineformat='ieee-be'; end
if get(handles.radiobutton_little_endian,'value'), machineformat='ieee-le'; end

% and read according to expected type
items = get(handles.menu_read_as,'String');
index_selected = get(handles.menu_read_as,'Value');
item_selected = items{index_selected};
readType = item_selected;

fprintf('data1 = fread(fid, inf, ''*%s'', 0, ''%s''); %% read data\n',readType,machineformat)
fprintf('fclose(fid); %% close file\n')
function ShowPreview()
% Show the first few data elements read with the current setting

handles=guidata(gcbo);
if numel(handles.UD.binaryDataVec)<100
    previewStr=num2str(handles.UD.binaryDataVec');
else
    previewStr=num2str(handles.UD.binaryDataVec(1:100)');
    previewStr=[previewStr '   .... '];
end
set(handles.text_preview,'string',previewStr);


% --- Creates and returns a handle to the GUI figure. 
function h1 = binareader_LayoutFcn(policy)
% policy - create a new figure or use a singleton. 'new' or 'reuse'.

persistent hsingleton;
if strcmpi(policy, 'reuse') & ishandle(hsingleton)
    h1 = hsingleton;
    return;
end

appdata = [];
appdata.GUIDEOptions = struct(...
    'active_h', [], ...
    'taginfo', struct(...
    'figure', 2, ...
    'uipanel', 7, ...
    'pushbutton', 7, ...
    'text', 4, ...
    'edit', 3, ...
    'radiobutton', 9), ...
    'override', 1, ...
    'release', 13, ...
    'resize', 'none', ...
    'accessibility', 'callback', ...
    'mfile', 1, ...
    'callbacks', 1, ...
    'singleton', 0, ...
    'syscolorfig', 1, ...
    'blocking', 0, ...
    'lastSavedFile', 'C:\Users\naor\Documents\MATLAB\binareader.m', ...
    'lastFilename', 'C:\Users\naor\nutils\mFiles\binareader.fig');
appdata.lastValidTag = 'figure_mainGUI';
appdata.GUIDELayoutEditor = [];
appdata.initTags = struct(...
    'handle', [], ...
    'tag', 'figure_mainGUI');

h1 = figure(...
'Units','characters',...
'Position',[103.8 29.0769230769231 131.8 32.3846153846154],...
'Visible','on',...
'Color',get(0,'defaultfigureColor'),...
'CloseRequestFcn',@(hObject,eventdata)binareader('figure_mainGUI_CloseRequestFcn',hObject,eventdata,guidata(hObject)),...
'IntegerHandle','off',...
'Colormap',[0 0 0.5625;0 0 0.625;0 0 0.6875;0 0 0.75;0 0 0.8125;0 0 0.875;0 0 0.9375;0 0 1;0 0.0625 1;0 0.125 1;0 0.1875 1;0 0.25 1;0 0.3125 1;0 0.375 1;0 0.4375 1;0 0.5 1;0 0.5625 1;0 0.625 1;0 0.6875 1;0 0.75 1;0 0.8125 1;0 0.875 1;0 0.9375 1;0 1 1;0.0625 1 1;0.125 1 0.9375;0.1875 1 0.875;0.25 1 0.8125;0.3125 1 0.75;0.375 1 0.6875;0.4375 1 0.625;0.5 1 0.5625;0.5625 1 0.5;0.625 1 0.4375;0.6875 1 0.375;0.75 1 0.3125;0.8125 1 0.25;0.875 1 0.1875;0.9375 1 0.125;1 1 0.0625;1 1 0;1 0.9375 0;1 0.875 0;1 0.8125 0;1 0.75 0;1 0.6875 0;1 0.625 0;1 0.5625 0;1 0.5 0;1 0.4375 0;1 0.375 0;1 0.3125 0;1 0.25 0;1 0.1875 0;1 0.125 0;1 0.0625 0;1 0 0;0.9375 0 0;0.875 0 0;0.8125 0 0;0.75 0 0;0.6875 0 0;0.625 0 0;0.5625 0 0],...
'MenuBar','none',...
'Name','binareader',...
'NumberTitle','off',...
'Resize','off',...
'PaperPosition',get(0,'defaultfigurePaperPosition'),...
'InvertHardcopy',get(0,'defaultfigureInvertHardcopy'),...
'HandleVisibility','callback',...
'Tag','figure_mainGUI',...
'UserData',[],...
'CreateFcn', {@local_CreateFcn, blanks(0), appdata} );

appdata = [];
appdata.lastValidTag = 'uipanel_file';

h2 = uipanel(...
'Parent',h1,...
'FontUnits',get(0,'defaultuipanelFontUnits'),...
'Units',get(0,'defaultuipanelUnits'),...
'Title','File',...
'Position',[0.036 0.463182897862233 0.379362670713202 0.463182897862233],...
'Clipping','off',...
'Tag','uipanel_file',...
'CreateFcn', {@local_CreateFcn, blanks(0), appdata} );

appdata = [];
appdata.lastValidTag = 'pushbutton_load';

h3 = uicontrol(...
'Parent',h2,...
'FontUnits',get(0,'defaultuicontrolFontUnits'),...
'Units','normalized',...
'String','Load',...
'Position',[0.660000000000001 0.85 0.29 0.119565217391304],...
'Callback',@(hObject,eventdata)binareader('pushbutton_load_Callback',hObject,eventdata,guidata(hObject)),...
'Children',[],...
'Tag','pushbutton_load',...
'CreateFcn', {@local_CreateFcn, blanks(0), appdata} );

appdata = [];
appdata.lastValidTag = 'pushbutton_save_to_ws';

h4 = uicontrol(...
'Parent',h2,...
'FontUnits',get(0,'defaultuicontrolFontUnits'),...
'Units','normalized',...
'String','Save to WS',...
'Position',[0.660000000000001 0.65 0.29 0.119565217391304],...
'Callback',@(hObject,eventdata)binareader('pushbutton_save_to_ws_Callback',hObject,eventdata,guidata(hObject)),...
'Children',[],...
'Tag','pushbutton_save_to_ws',...
'CreateFcn', {@local_CreateFcn, blanks(0), appdata} );

appdata = [];
appdata.lastValidTag = 'pushbutton_save_as_txt';

h5 = uicontrol(...
'Parent',h2,...
'FontUnits',get(0,'defaultuicontrolFontUnits'),...
'Units','normalized',...
'String','Save as .txt',...
'Position',[0.660000000000001 0.45 0.29 0.119565217391304],...
'Callback',@(hObject,eventdata)binareader('pushbutton_save_as_txt_Callback',hObject,eventdata,guidata(hObject)),...
'Children',[],...
'Tag','pushbutton_save_as_txt',...
'CreateFcn', {@local_CreateFcn, blanks(0), appdata} );

appdata = [];
appdata.lastValidTag = 'pushbutton_save_as_mat';

h6 = uicontrol(...
'Parent',h2,...
'FontUnits',get(0,'defaultuicontrolFontUnits'),...
'Units','normalized',...
'String','Save as .mat',...
'Position',[0.660000000000001 0.25 0.29 0.119565217391304],...
'Callback',@(hObject,eventdata)binareader('pushbutton_save_as_mat_Callback',hObject,eventdata,guidata(hObject)),...
'Children',[],...
'Tag','pushbutton_save_as_mat',...
'CreateFcn', {@local_CreateFcn, blanks(0), appdata} );

appdata = [];
appdata.lastValidTag = 'pushbutton_show_call';

h66 = uicontrol(...
'Parent',h2,...
'FontUnits',get(0,'defaultuicontrolFontUnits'),...
'Units','normalized',...
'String','Commands',...
'Position',[0.660000000000001 0.05 0.29 0.119565217391304],...
'Callback',@(hObject,eventdata)ShowCall(),...
'Children',[],...
'Tag','pushbutton_show_call',...
'CreateFcn', {@local_CreateFcn, blanks(0), appdata} );

appdata = [];
appdata.lastValidTag = 'text_file_info';

h7 = uicontrol(...
'Parent',h2,...
'FontUnits',get(0,'defaultuicontrolFontUnits'),...
'Units','characters',...
'HorizontalAlignment','left',...
'String',blanks(0),...
'Style','text',...
'Position',[2 9.46153846153846 26.6 2.53846153846154],...
'Children',[],...
'Visible','off',...
'Tag','text_file_info',...
'FontSize',10,...
'CreateFcn', {@local_CreateFcn, blanks(0), appdata} );

appdata = [];
appdata.lastValidTag = 'uipanel_header';

h8 = uipanel(...
'Parent',h1,...
'FontUnits',get(0,'defaultuipanelFontUnits'),...
'Units',get(0,'defaultuipanelUnits'),...
'Title','Header',...
'Position',[0.5 0.463182897862233 0.455 0.463182897862233],...
'Clipping','off',...
'Tag','uipanel_header',...
'CreateFcn', {@local_CreateFcn, blanks(0), appdata} );

appdata = [];
appdata.lastValidTag = 'text_header_display';

h9 = uicontrol(...
'Parent',h8,...
'FontUnits',get(0,'defaultuicontrolFontUnits'),...
'Units','normalized',...
'HorizontalAlignment','left',...
'Max',2,...
'String',blanks(0),...
'Style','edit',...
'Position',[0.05 0.05 0.9 0.7],...
'Children',[],...
'Enable','inactive',...
'Tag','text_header_display',...
'CreateFcn', {@local_CreateFcn, blanks(0), appdata} );

appdata = [];
appdata.lastValidTag = 'edit_header_lines_counter';

h10 = uicontrol(...
'Parent',h8,...
'FontUnits',get(0,'defaultuicontrolFontUnits'),...
'Units','characters',...
'String','0',...
'Style','edit',...
'Position',[26.8 11.5384615384615 7 1.69230769230769],...
'BackgroundColor',[1 1 1],...
'Callback',@(hObject,eventdata)binareader('edit_header_lines_counter_Callback',hObject,eventdata,guidata(hObject)),...
'Children',[],...
'CreateFcn', {@local_CreateFcn, @(hObject,eventdata)binareader('edit_header_lines_counter_CreateFcn',hObject,eventdata,guidata(hObject)), appdata} ,...
'Tag','edit_header_lines_counter');

appdata = [];
appdata.lastValidTag = 'text3';

h11 = uicontrol(...
'Parent',h8,...
'FontUnits',get(0,'defaultuicontrolFontUnits'),...
'Units','characters',...
'String','Header lines:',...
'Style','text',...
'Position',[3 11.8461538461538 16.6 1.07692307692308],...
'Children',[],...
'Tag','text3',...
'CreateFcn', {@local_CreateFcn, blanks(0), appdata} );

appdata = [];
appdata.lastValidTag = 'pushbutton_increment_header_lines_counter';

h12 = uicontrol(...
'Parent',h8,...
'FontUnits',get(0,'defaultuicontrolFontUnits'),...
'Units','characters',...
'String','+',...
'Position',[36.2 11.5384615384615 6 1.69230769230769],...
'Callback',@(hObject,eventdata)binareader('pushbutton_increment_header_lines_counter_Callback',hObject,eventdata,guidata(hObject)),...
'Children',[],...
'Tag','pushbutton_increment_header_lines_counter',...
'FontSize',10,...
'FontWeight','bold',...
'CreateFcn', {@local_CreateFcn, blanks(0), appdata} );

appdata = [];
appdata.lastValidTag = 'pushbutton_decrement_header_lines_counter';

h13 = uicontrol(...
'Parent',h8,...
'FontUnits',get(0,'defaultuicontrolFontUnits'),...
'Units','characters',...
'String','-',...
'Position',[18.8 11.5384615384615 6 1.69230769230769],...
'Callback',@(hObject,eventdata)binareader('pushbutton_decrement_header_lines_counter_Callback',hObject,eventdata,guidata(hObject)),...
'Children',[],...
'Tag','pushbutton_decrement_header_lines_counter',...
'FontSize',12,...
'FontWeight','bold',...
'CreateFcn', {@local_CreateFcn, blanks(0), appdata} );

appdata = [];
appdata.lastValidTag = 'uipanel_preview';

h14 = uipanel(...
'Parent',h1,...
'FontUnits',get(0,'defaultuipanelFontUnits'),...
'Units',get(0,'defaultuipanelUnits'),...
'Title','Preview',...
'Position',[0.036 0.02 0.919 0.42],...
'Clipping','off',...
'Tag','uipanel_preview',...
'CreateFcn', {@local_CreateFcn, blanks(0), appdata} );

appdata = [];
appdata.lastValidTag = 'uipanel_read_as';

h15 = uibuttongroup(...
'Parent',h14,...
'FontUnits','points',...
'Units','normalized',...
'SelectionChangeFcn',@(hObject,eventdata)binareader('uipanel_read_as_SelectionChangeFcn',get(hObject,'SelectedObject'),eventdata,guidata(get(hObject,'SelectedObject'))),...
'Title','Read as:',...
'Position',[0.806 0.388 0.179700499168053 0.6],...
'Clipping','off',...
'Tag','uipanel_read_as',...
'CreateFcn', {@local_CreateFcn, blanks(0), appdata} );

appdata = [];
appdata.lastValidTag = 'radiobutton_read_as_single';

% h16 = uicontrol(...
% 'Parent',h15,...
% 'FontUnits',get(0,'defaultuicontrolFontUnits'),...
% 'Units','normalized',...
% 'String','Single',...
% 'Style','radiobutton',...
% 'Value',1,...
% 'Position',[0.36 0.784090909090909 0.548076923076923 0.204545454545455],...
% 'Children',[],...
% 'Tag','radiobutton_read_as_single',...
% 'CreateFcn', {@local_CreateFcn, blanks(0), appdata} );
% 
% appdata = [];
% appdata.lastValidTag = 'radiobutton_read_as_double';

h100 = uicontrol(...
'Parent',h15,...
'FontUnits',get(0,'defaultuicontrolFontUnits'),...
'Units','normalized',...
'String',{'double','single','int32','int64','uint32','uint64','int8','uint8','int16','uint16'},...
'Style','popupmenu',...
'Value',1,...
'Position',[0.16 0.684090909090909 0.64 0.2],...
'Children',[],...
'Tag','menu_read_as',...
'Callback',@(~,~)BinaryRead(),...
'CreateFcn', {@local_CreateFcn, blanks(0), appdata} );

appdata = [];
appdata.lastValidTag = 'menu_rad_as';

h20 = uibuttongroup(...
'Parent',h14,...
'FontUnits','points',...
'Units','normalized',...
'SelectionChangeFcn',@(hObject,eventdata)binareader('uipanel_endiandness_SelectionChangeFcn',get(hObject,'SelectedObject'),eventdata,guidata(get(hObject,'SelectedObject'))),...
'Title','Endiandness',...
'Position',[0.806988352745424 0.056 0.179700499168053 0.325],...
'Clipping','off',...
'Tag','uipanel_endiandness',...
'CreateFcn', {@local_CreateFcn, blanks(0), appdata} );

appdata = [];
appdata.lastValidTag = 'radiobutton_big_endian';

h21 = uicontrol(...
'Parent',h20,...
'FontUnits',get(0,'defaultuicontrolFontUnits'),...
'Units','normalized',...
'String','Big',...
'Style','radiobutton',...
'Value',get(0,'defaultuicontrolValue'),...
'Position',[0.36 0.6 0.548076923076923 0.457142857142857],...
'Children',[],...
'Tag','radiobutton_big_endian',...
'UserData',[],...
'CreateFcn', {@local_CreateFcn, blanks(0), appdata} );

appdata = [];
appdata.lastValidTag = 'radiobutton_little_endian';

h22 = uicontrol(...
'Parent',h20,...
'FontUnits',get(0,'defaultuicontrolFontUnits'),...
'Units','normalized',...
'String','Little',...
'Style','radiobutton',...
'Value',1,...
'Position',[0.36 0.142857142857143 0.548076923076923 0.457142857142857],...
'Children',[],...
'Tag','radiobutton_little_endian',...
'CreateFcn', {@local_CreateFcn, blanks(0), appdata} );

appdata = [];
appdata.lastValidTag = 'text_preview';

h23 = uicontrol(...
'Parent',h14,...
'FontUnits',get(0,'defaultuicontrolFontUnits'),...
'Units','normalized',...
'HorizontalAlignment','left',...
'Max',2,...
'Style','edit',...
'Position',[0.0199667221297837 0.05625 0.760399334442596 0.92],...
'Children',[],...
'Enable','inactive',...
'Tag','text_preview',...
'UserData',[],...
'CreateFcn', {@local_CreateFcn, blanks(0), appdata} );


hsingleton = h1;


% --- Set application data first then calling the CreateFcn. 
function local_CreateFcn(hObject, eventdata, createfcn, appdata)

if ~isempty(appdata)
   names = fieldnames(appdata);
   for i=1:length(names)
       name = char(names(i));
       setappdata(hObject, name, getfield(appdata,name));
   end
end

if ~isempty(createfcn)
   if isa(createfcn,'function_handle')
       createfcn(hObject, eventdata);
   else
       eval(createfcn);
   end
end


% --- Handles default GUIDE GUI creation and callback dispatch
function varargout = gui_mainfcn(gui_State, varargin)

gui_StateFields =  {'gui_Name'
    'gui_Singleton'
    'gui_OpeningFcn'
    'gui_OutputFcn'
    'gui_LayoutFcn'
    'gui_Callback'};
gui_Mfile = '';
for i=1:length(gui_StateFields)
    if ~isfield(gui_State, gui_StateFields{i})
        error(message('MATLAB:guide:StateFieldNotFound', gui_StateFields{ i }, gui_Mfile));
    elseif isequal(gui_StateFields{i}, 'gui_Name')
        gui_Mfile = [gui_State.(gui_StateFields{i}), '.m'];
    end
end

numargin = length(varargin);

if numargin == 0
    % BINAREADER
    % create the GUI only if we are not in the process of loading it
    % already
    gui_Create = true;
elseif local_isInvokeActiveXCallback(gui_State, varargin{:})
    % BINAREADER(ACTIVEX,...)
    vin{1} = gui_State.gui_Name;
    vin{2} = [get(varargin{1}.Peer, 'Tag'), '_', varargin{end}];
    vin{3} = varargin{1};
    vin{4} = varargin{end-1};
    vin{5} = guidata(varargin{1}.Peer);
    feval(vin{:});
    return;
elseif local_isInvokeHGCallback(gui_State, varargin{:})
    % BINAREADER('CALLBACK',hObject,eventData,handles,...)
    gui_Create = false;
else
    % BINAREADER(...)
    % create the GUI and hand varargin to the openingfcn
    gui_Create = true;
end

if ~gui_Create
    % In design time, we need to mark all components possibly created in
    % the coming callback evaluation as non-serializable. This way, they
    % will not be brought into GUIDE and not be saved in the figure file
    % when running/saving the GUI from GUIDE.
    designEval = false;
    if (numargin>1 && ishghandle(varargin{2}))
        fig = varargin{2};
        while ~isempty(fig) && ~ishghandle(fig,'figure')
            fig = get(fig,'parent');
        end
        
        designEval = isappdata(0,'CreatingGUIDEFigure') || (isscalar(fig)&&isprop(fig,'GUIDEFigure'));
    end
        
    if designEval
        beforeChildren = findall(fig);
    end
    
    % evaluate the callback now
    varargin{1} = gui_State.gui_Callback;
    if nargout
        [varargout{1:nargout}] = feval(varargin{:});
    else       
        feval(varargin{:});
    end
    
    % Set serializable of objects created in the above callback to off in
    % design time. Need to check whether figure handle is still valid in
    % case the figure is deleted during the callback dispatching.
    if designEval && ishghandle(fig)
        set(setdiff(findall(fig),beforeChildren), 'Serializable','off');
    end
else
    if gui_State.gui_Singleton
        gui_SingletonOpt = 'reuse';
    else
        gui_SingletonOpt = 'new';
    end

    % Check user passing 'visible' P/V pair first so that its value can be
    % used by oepnfig to prevent flickering
    gui_Visible = 'auto';
    gui_VisibleInput = '';
    for index=1:2:length(varargin)
        if length(varargin) == index || ~ischar(varargin{index})
            break;
        end

        % Recognize 'visible' P/V pair
        len1 = min(length('visible'),length(varargin{index}));
        len2 = min(length('off'),length(varargin{index+1}));
        if ischar(varargin{index+1}) && strncmpi(varargin{index},'visible',len1) && len2 > 1
            if strncmpi(varargin{index+1},'off',len2)
                gui_Visible = 'invisible';
                gui_VisibleInput = 'off';
            elseif strncmpi(varargin{index+1},'on',len2)
                gui_Visible = 'visible';
                gui_VisibleInput = 'on';
            end
        end
    end
    
    % Open fig file with stored settings.  Note: This executes all component
    % specific CreateFunctions with an empty HANDLES structure.

    
    % Do feval on layout code in m-file if it exists
    gui_Exported = ~isempty(gui_State.gui_LayoutFcn);
    % this application data is used to indicate the running mode of a GUIDE
    % GUI to distinguish it from the design mode of the GUI in GUIDE. it is
    % only used by actxproxy at this time.   
    setappdata(0,genvarname(['OpenGuiWhenRunning_', gui_State.gui_Name]),1);
    if gui_Exported
        gui_hFigure = feval(gui_State.gui_LayoutFcn, gui_SingletonOpt);

        % make figure invisible here so that the visibility of figure is
        % consistent in OpeningFcn in the exported GUI case
        if isempty(gui_VisibleInput)
            gui_VisibleInput = get(gui_hFigure,'Visible');
        end
        set(gui_hFigure,'Visible','off')

        % openfig (called by local_openfig below) does this for guis without
        % the LayoutFcn. Be sure to do it here so guis show up on screen.
        movegui(gui_hFigure,'onscreen');
    else
        gui_hFigure = local_openfig(gui_State.gui_Name, gui_SingletonOpt, gui_Visible);
        % If the figure has InGUIInitialization it was not completely created
        % on the last pass.  Delete this handle and try again.
        if isappdata(gui_hFigure, 'InGUIInitialization')
            delete(gui_hFigure);
            gui_hFigure = local_openfig(gui_State.gui_Name, gui_SingletonOpt, gui_Visible);
        end
    end
    if isappdata(0, genvarname(['OpenGuiWhenRunning_', gui_State.gui_Name]))
        rmappdata(0,genvarname(['OpenGuiWhenRunning_', gui_State.gui_Name]));
    end

    % Set flag to indicate starting GUI initialization
    setappdata(gui_hFigure,'InGUIInitialization',1);

    % Fetch GUIDE Application options
    gui_Options = getappdata(gui_hFigure,'GUIDEOptions');
    % Singleton setting in the GUI M-file takes priority if different
    gui_Options.singleton = gui_State.gui_Singleton;

    if ~isappdata(gui_hFigure,'GUIOnScreen')
        % Adjust background color
        if gui_Options.syscolorfig
            set(gui_hFigure,'Color', get(0,'DefaultUicontrolBackgroundColor'));
        end

        % Generate HANDLES structure and store with GUIDATA. If there is
        % user set GUI data already, keep that also.
        data = guidata(gui_hFigure);
        handles = guihandles(gui_hFigure);
        if ~isempty(handles)
            if isempty(data)
                data = handles;
            else
                names = fieldnames(handles);
                for k=1:length(names)
                    data.(char(names(k)))=handles.(char(names(k)));
                end
            end
        end
        guidata(gui_hFigure, data);
    end

    % Apply input P/V pairs other than 'visible'
    for index=1:2:length(varargin)
        if length(varargin) == index || ~ischar(varargin{index})
            break;
        end

        len1 = min(length('visible'),length(varargin{index}));
        if ~strncmpi(varargin{index},'visible',len1)
            try set(gui_hFigure, varargin{index}, varargin{index+1}), catch break, end
        end
    end

    % If handle visibility is set to 'callback', turn it on until finished
    % with OpeningFcn
    gui_HandleVisibility = get(gui_hFigure,'HandleVisibility');
    if strcmp(gui_HandleVisibility, 'callback')
        set(gui_hFigure,'HandleVisibility', 'on');
    end

    feval(gui_State.gui_OpeningFcn, gui_hFigure, [], guidata(gui_hFigure), varargin{:});

    if isscalar(gui_hFigure) && ishghandle(gui_hFigure)
        % Handle the default callbacks of predefined toolbar tools in this
        % GUI, if any
        guidemfile('restoreToolbarToolPredefinedCallback',gui_hFigure); 
        
        % Update handle visibility
        set(gui_hFigure,'HandleVisibility', gui_HandleVisibility);

        % Call openfig again to pick up the saved visibility or apply the
        % one passed in from the P/V pairs
        if ~gui_Exported
            gui_hFigure = local_openfig(gui_State.gui_Name, 'reuse',gui_Visible);
        elseif ~isempty(gui_VisibleInput)
            set(gui_hFigure,'Visible',gui_VisibleInput);
        end
        if strcmpi(get(gui_hFigure, 'Visible'), 'on')
            figure(gui_hFigure);
            
            if gui_Options.singleton
                setappdata(gui_hFigure,'GUIOnScreen', 1);
            end
        end

        % Done with GUI initialization
        if isappdata(gui_hFigure,'InGUIInitialization')
            rmappdata(gui_hFigure,'InGUIInitialization');
        end

        % If handle visibility is set to 'callback', turn it on until
        % finished with OutputFcn
        gui_HandleVisibility = get(gui_hFigure,'HandleVisibility');
        if strcmp(gui_HandleVisibility, 'callback')
            set(gui_hFigure,'HandleVisibility', 'on');
        end
        gui_Handles = guidata(gui_hFigure);
    else
        gui_Handles = [];
    end

    if nargout
        [varargout{1:nargout}] = feval(gui_State.gui_OutputFcn, gui_hFigure, [], gui_Handles);
    else
        feval(gui_State.gui_OutputFcn, gui_hFigure, [], gui_Handles);
    end

    if isscalar(gui_hFigure) && ishghandle(gui_hFigure)
        set(gui_hFigure,'HandleVisibility', gui_HandleVisibility);
    end
end

function gui_hFigure = local_openfig(name, singleton, visible)

% openfig with three arguments was new from R13. Try to call that first, if
% failed, try the old openfig.
if nargin('openfig') == 2
    % OPENFIG did not accept 3rd input argument until R13,
    % toggle default figure visible to prevent the figure
    % from showing up too soon.
    gui_OldDefaultVisible = get(0,'defaultFigureVisible');
    set(0,'defaultFigureVisible','off');
    gui_hFigure = matlab.hg.internal.openfigLegacy(name, singleton);
    set(0,'defaultFigureVisible',gui_OldDefaultVisible);
else
    % Call version of openfig that accepts 'auto' option"
    gui_hFigure = matlab.hg.internal.openfigLegacy(name, singleton, visible);  
%     %workaround for CreateFcn not called to create ActiveX
%     if feature('HGUsingMATLABClasses')
%         peers=findobj(findall(allchild(gui_hFigure)),'type','uicontrol','style','text');    
%         for i=1:length(peers)
%             if isappdata(peers(i),'Control')
%                 actxproxy(peers(i));
%             end            
%         end
%     end
end

function result = local_isInvokeActiveXCallback(gui_State, varargin)

try
    result = ispc && iscom(varargin{1}) ...
             && isequal(varargin{1},gcbo);
catch
    result = false;
end

function result = local_isInvokeHGCallback(gui_State, varargin)

try
    fhandle = functions(gui_State.gui_Callback);
    result = ~isempty(findstr(gui_State.gui_Name,fhandle.file)) || ...
             (ischar(varargin{1}) ...
             && isequal(ishghandle(varargin{2}), 1) ...
             && (~isempty(strfind(varargin{1},[get(varargin{2}, 'Tag'), '_'])) || ...
                ~isempty(strfind(varargin{1}, '_CreateFcn'))) );
catch
    result = false;
end


