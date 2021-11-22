clear 
close all
uno = arduino;
dev = device(uno,'I2CAddress','0x68');
Registers.Reg26 = readRegister(dev, 26);
Registers.Reg27 = readRegister(dev, 27);
Registers.Reg28 = readRegister(dev, 28);
clear dev
imu = mpu6050(uno, 'SamplesPerRead', 1, 'OutputFormat','matrix');
viewer = HelperOrientationViewer;
figure('units','normalized','outerposition',[0 0 1 1])
% subplot(4,1, 1)
% Axl_1 = animatedline('Color',[1 0 0]); 
% Axl_2 = animatedline('Color',[0 1 0]);
% Axl_3 = animatedline('Color',[0 0 1]);
% xlabel('Time (s)')
% ylabel('Rotation (degrees)')
% legend('z-axis','y-axis','x-axis','Location', 'northwest')
% title('Orientation')
% grid on
subplot(3,1,1)
Ax2_1 = animatedline('Color',[1 0 0]); 
Ax2_2 = animatedline('Color',[0 1 0]);
Ax2_3 = animatedline('Color',[0 0 1]);
xlabel('Time (s)')
ylabel('Acceleration (m/s^2)')
legend('z-axis','y-axis','x-axis','Location', 'northwest')
title('Accelerometer Data')
grid on
subplot(3,1,2)
Ax3_1 = animatedline('Color',[1 0 0]); 
Ax3_2 = animatedline('Color',[0 1 0]);
Ax3_3 = animatedline('Color',[0 0 1]);
xlabel('Time (s)')
ylabel('Angular Velocity (rad/s)')
legend('z-axis','y-axis','x-axis','Location', 'northwest')
title('Gyroscope Data')
grid on
subplot(3,1,3)
Ax4_1 = animatedline('Color',[1 0 0]); 
Ax4_2 = animatedline('Color',[0 1 0]);
Ax4_3 = animatedline('Color',[0 0 1]);
xlabel('Time (s)')
ylabel('Rotation (degrees)')
legend('z-axis','y-axis','x-axis','Location', 'northwest')
title('Ang Vel Data')
grid on
[~, timeZero] = readAcceleration(imu);
% fuse = complementaryFilter;
% fuse.AccelerometerGain = 0.5;
% fuse.HasMagnetometer = false;
fuse = imufilter;
fuse.AccelerometerNoise = 0.07;
fuse.GyroscopeDriftNoise = 0.055;
fuse.GyroscopeNoise = 0.5;
fuseLinearAccelerationDecayFactor = 0.9;
cfg = tunerconfig('imufilter');
j=1;
while true
    [accReadings, gyroReadings, time] = imu.read;
    q = fuse(accReadings, gyroReadings);
    orientation = eulerd(q,'ZYX','frame');
    time = etime(datevec(time), datevec(timeZero));
    addpoints(Ax4_1,time,orientation(1));
    addpoints(Ax4_2,time,orientation(2));
    addpoints(Ax4_3,time,orientation(3));
%     addpoints(Ax4_1,time,AngVel(1));
%     addpoints(Ax4_2,time,AngVel(2));
%     addpoints(Ax4_3,time,AngVel(3));
    addpoints(Ax2_1,time,accReadings(1));
    addpoints(Ax2_2,time,accReadings(2));
    addpoints(Ax2_3,time,accReadings(3));
    addpoints(Ax3_1,time,gyroReadings(1));
    addpoints(Ax3_2,time,gyroReadings(2));
    addpoints(Ax3_3,time,gyroReadings(3));
    drawnow
    for j = numel(q)
        viewer(q(j));
    end
    j=j+1; 
end

