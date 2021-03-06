clear 
close all
uno = arduino('/dev/cu.usbmodem1101','Uno','Libraries',);
dev = device(uno,'I2CAddress','0x68');
for i= 1:105
    Registers(i) = readRegister(dev, i);
end
% writeRegister(dev, 37, 0);in=
clear dev
TuneSamples = 500;
imu = mpu9250(uno, 'SamplesPerRead', TuneSamples);
SensorData = imu.read;
SensorTable = timetable2table(SensorData);
SensorTable = removevars(SensorTable,1);
SensorTable.Properties.VariableNames = {'Accelerometer','Gyroscope'};
%% 
% GyroMeanX=mean(SensorTable.Gyroscope(:,1));
% GyroMeanY=mean(SensorTable.Gyroscope(:,2));
% GyroMeanZ=mean(SensorTable.Gyroscope(:,3));
% SensorTable.Gyroscope(:,1) = SensorTable.Gyroscope(:,1)-GyroMeanX;
% SensorTable.Gyroscope(:,2) = SensorTable.Gyroscope(:,1)-GyroMeanY;
% SensorTable.Gyroscope(:,3) = SensorTable.Gyroscope(:,1)-GyroMeanZ;
%% 
release(imu)
clear uno imu
uno = arduino;
imu = mpu9250(uno, 'SamplesPerRead', 1, 'OutputFormat','matrix');
[~, timeZero] = readAcceleration(imu);
%% Complementary filter 
% fuse = complementaryFilter;
% fuse.AccelerometerGain = 0.5;
% fuse.HasMagnetometer = false;
%% 
Fuse = ahrsfilter;
%% Manual parameters 
% Fuse.AccelerometerNoise = 0.07;
% Fuse.GyroscopeDriftNoise = 0.055;
% Fuse.GyroscopeNoise = 0.5;
% Fuse.LinearAccelerationDecayFactor = 0.9;
%% 
% cfg = tunerconfig('imufilter', 'MaxIterations', 50);
% % cfg.StepForward = 1.1;
% % cfg.ObjectiveLimit = 10;
% GroundTruth = table(repmat(quaternion(1,0,0,0),TuneSamples,1), ...
%     'VariableNames', {'Orientation'});
% tune(Fuse, SensorTable, GroundTruth, cfg);

viewer = HelperOrientationViewer;
figure('units','normalized','outerposition',[0 0 1 1])
subplot(3,1,1)
Ax1_1 = animatedline('Color',[1 0 0]); 
Ax1_2 = animatedline('Color',[0 1 0]);
Ax1_3 = animatedline('Color',[0 0 1]);
xlabel('Time (s)')
ylabel('Acceleration (m/s^2)')
legend('z-axis','y-axis','x-axis','Location', 'northwest')
title('Accelerometer Data')
grid on
subplot(3,1,2)
Ax2_1 = animatedline('Color',[1 0 0]); 
Ax2_2 = animatedline('Color',[0 1 0]);
Ax2_3 = animatedline('Color',[0 0 1]);
xlabel('Time (s)')
ylabel('Angular Velocity (rad/s)')
legend('z-axis','y-axis','x-axis','Location', 'northwest')
title('Gyroscope Data')
grid on
%% Additional animated line
subplot(3,1,3)
Ax3_1 = animatedline('Color',[1 0 0]); 
Ax3_2 = animatedline('Color',[0 1 0]);
Ax3_3 = animatedline('Color',[0 0 1]);
xlabel('Time (s)')
ylabel('Euler angles (degrees)')
legend('z-axis','y-axis','x-axis','Location', 'northwest')
title('Orientation')
grid on
%% 
j=1;
while true
    [accReadings, gyroReadings, time] = imu.read;
%     gyroReadings = gyroReadings - [GyroMeanX,GyroMeanY,GyroMeanZ]; 
    q = Fuse(accReadings, gyroReadings);
    time = etime(datevec(time), datevec(timeZero));
    addpoints(Ax1_1,time,accReadings(1));
    addpoints(Ax1_2,time,accReadings(2));
    addpoints(Ax1_3,time,accReadings(3));
    addpoints(Ax2_1,time,gyroReadings(1));
    addpoints(Ax2_2,time,gyroReadings(2));
    addpoints(Ax2_3,time,gyroReadings(3));
        %% Additional animated line plotting 
    orientation = eulerd(q,'ZYX','frame');
    addpoints(Ax3_1,time,orientation(1));
    addpoints(Ax3_2,time,orientation(2));
    addpoints(Ax3_3,time,orientation(3));
%% 
    drawnow
    for j = numel(q)
        viewer(q(j));
    end
    j=j+1; 
end

