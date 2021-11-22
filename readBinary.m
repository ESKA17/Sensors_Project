clear
folders = dir();
filenames = extractfield(folders, 'name');
obr = filenames{4};
fileID = fopen(obr, 'r', 'n');
% 
% A = fread(fileID);
% % B = fread(fileID,'ubit64');
% % C = fscanf(fileID, '%s'); 
% % d = C(5:12);
% e = char(A, [], 'en-US');
% strcat(e(1:2000))
% fclose(fileID);

% 
% fid = fopen('C:\Users\Saba\Desktop\New folder\OBR_SpotScan07_27_2021_11_55_48_Scan17', 'r', 'n'); % open file
% fseek(fid, 14766, 'bof'); % position read head after header
% data1 = fread(fid, 'double'); % read data
% fclose(fid);
opts = detectImportOptions(obr);

g = readtable(obr,'FileType', 'delimitedtext', 'ReadRowNames', 0, ...
    'VariableNamingRule' , 'preserve', 'Delimiter', 'tab', 'HeaderLines', 22,...
    'Encoding', 'system', 'BinaryType','uint64');