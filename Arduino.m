% % % serialportlist("available")'
% % arduinoObj = serialport("COM6",9600);
% % configureTerminator(arduinoObj,"CR/LF");
% % flush(arduinoObj);
% % arduinoObj.UserData = struct("Data",[],"Count",1);
% % configureCallback(arduinoObj,"terminator",@readSineWaveData);
% % function readSineWaveData(src, ~)
% % 
% % % Read the ASCII data from the serialport object.
% % data = readline(src);
% % 
% % % Convert the string data to numeric type and save it in the UserData
% % % property of the serialport object.
% % src.UserData.Data(end+1) = str2double(data);
% % 
% % % Update the Count value of the serialport object.
% % src.UserData.Count = src.UserData.Count + 1;
% % 
% % % If 1001 data points have been collected from the Arduino, switch off the
% % % callbacks and plot the data.
% % if src.UserData.Count > 1001
% %     configureCallback(src, "off");
% %     plot(src.UserData.Data(2:end));
% % end
% % end
% 
% a=arduino('com6','uno','libraries','Pololu/LSM303');


% Clearing
clear
%Init
uno = arduino;
    
% Hello blink
for i = 1:4
      writeDigitalPin(uno, 'D3', 1);
      pause(0.25);
      writeDigitalPin(uno, 'D3', 0);
      pause(0.25);
end
addrs = scanI2CBus(uno);
%Disable Sleep mode
mpu=device(uno,'I2CAddress','0x68'); %mpu adress is normally 0x68
writeRegister(mpu, hex2dec('6B'), hex2dec('00'), 'int16'); %reset
%Read Data
data=zeros(10000,14,'int8'); %prelocating for the speed
j=1;
Axl_1 = animatedline('Color',[1 0 0]); 
Axl_2 = animatedline('Color',[0 1 0]);
Axl_3 = animatedline('Color',[0 0 1]);
legend('Axl_x','Axl_y','Axl_z');

% loop
while(true)
    x=1;
    for i=59:72 % 14 Data Registers for Axl,Temp,Gyro
        data(j,x)= readRegister(mpu, i, 'int8');
        x=x+1;
    end
    
    y = swapbytes(typecast(data(j,:), 'int16'));
    
    addpoints(Axl_1,j,double(y(1)));
    addpoints(Axl_2,j,double(y(2)));
    addpoints(Axl_3,j,double(y(3)));
    j=j+1;
    drawnow limitrate;
end
