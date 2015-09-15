% inverse kinematics with input from 3D mouse 
function ik_3DMouse()
	clc;
	clear all;
	close all;	
    addpath('spnav');

    % global varibles
    global max_angles min_angles d1 a1 a2 a3 d5
    
    max_angles = deg2rad([169, 155, 151, 102.5, 167.5]);
    min_angles = deg2rad([-169, 0 -146, -102.5, -167.5]);
    
	d1 = 14.7;
    a1 = 3.3;
    a2 = 15.5;
    a3 = 13.5;
    d5 = 21.75;
    
    % create stage to show youBot
	ax = createStage([-6 10 -10 10 -2 12], [-24 41]);
    set(gcf,'units','normalized','outerposition',[0 0 1 1])
%     set(ax, 'CameraUpVector', [1 0 0], 'CameraPosition', [12, 15, -3], 'CameraTarget', [1 0 5]);
	% goal pose
    t_goal = triade(T_unity(), [], 4, 0.1);
%     createObject(transform(T_shift(-1, 0, 0), geoGeneric([0, -10 -5; 0 -10 15; 0 10 15; 0 10 -5], [1 2 3 4])), 'FaceColor', [0.9 0.9 0.9]);
	camlight();
	linkColors = {[.4 .4 .4], [1 1 1], [.5 1 .5], [.5 .5 1], [.5 1 1], [1 .5 .5]};
	
    % creat and init coarse youBot arm modell
	robot = youBot(d1, a1, a2, a3, d5);
	robot.colorLinks(linkColors{1}, linkColors{2}, linkColors{3}, linkColors{4}, linkColors{5}, linkColors{6});
	robot.setTransparency(0.5);
    
	% UI controls for display
    hArmConfig1 = uicontrol('Style', 'checkbox', 'String', 'k_arm1 = -1', 'Position', [5, 85, 215, 20], 'Callback', @updateFromSliders, 'Value', 0);
    hArmConfig3 = uicontrol('Style', 'checkbox', 'String', 'k_arm3 = -1', 'Position', [5, 65, 215, 20], 'Callback', @updateFromSliders, 'Value', 0);
	hXText = uicontrol('Style', 'text', 'Position', [5 45 80 20], 'String', 'X', 'ForegroundColor', brighten([1 0 0], -0.5));
    hYText = uicontrol('Style', 'text', 'Position', [5 25 80 20], 'String', 'Y', 'ForegroundColor', brighten([0 1 0], -0.5));
    hZText = uicontrol('Style', 'text', 'Position', [5 5 80 20], 'String', 'Z', 'ForegroundColor', brighten([0 0 1], -0.5));
    hPhiText = uicontrol('Style', 'text', 'Position', [85 45 80 20], 'String', 'φ', 'ForegroundColor', brighten([0 0 0], -0.5));
    hGammaText = uicontrol('Style', 'text', 'Position', [85 25 80 20], 'String', 'γ', 'ForegroundColor', brighten([0 0 0], -0.5));    
	
    % init 3D mous
    if ~spnav('open')
        clear spnav;
        if ~spnav('open')    
            error('Could not open Space Navigator device. Make sure that the device is attached and spacenavd is running!');
        end
    end
    minTrans = 0.1;
    minRot = 0.1;
    
    % home position
    x0 = -5;
    y0 = 0;
    z0 = 44;
    phi0 = 65 * pi / 180;
    gamma0 = 0;
    
    % read 3D mouse input and apply inverse kinematik
    run = true;
    while run
    updateFrom3DMous();	
    pause(0.1);
    end


	function updateFrom3DMous(varargin)		
        res = spnav();
		x = res.trans(1);
		y = res.trans(3);
		z = res.trans(2);
		rx = res.rot(1);
		ry = res.rot(3);
		rz = res.rot(2);
		fprintf('x/y/z = %5.2f/%5.2f/%5.2f, rx/ry/rz = %5.2f/%5.2f/%5.2f', x, y, z, rx, ry, rz);
        for i = 1:numel(res.buttons)
			if res.buttons(i)
				if res.pressEvents(i) > 0
					fprintf(', button %d pressed', i);
				else fprintf(', button %d down', i);
				end
			elseif res.releaseEvents(i) > 0
				fprintf(', button %d released', i);
			end				
        end
		fprintf('\n');
        if res.pressEvents(1) > 0
            closeHandler(ax); 
        end
        
        % parameter for tuning 3D mouse sencitivity
        kv=0.1;
        if abs(x)>=minTrans
            px = x0+kv*x;
        else
            px = x0;
        end
        if abs(y)>=minTrans
            py = y0+kv*y;
        else
            py = y0;
        end
        if abs(z)>=minTrans
            pz = z0+kv*z;
        else
            pz = z0;
        end
        if abs(ry)>=minRot
            phi = phi0+kv*ry;
        else
            phi = phi0;
        end
        if abs(rz)>=minRot
            gamma = gamma0+kv*rz;
        else
            gamma = gamma0;
        end  
        
        x0 = px;
        y0 = py;
        z0 = pz;
        phi0 = phi;
        gamma0 = gamma;
        
        % show values
        set(hXText, 'String', sprintf('X = %0.2f cm', px));
        set(hYText, 'String', sprintf('Y = %0.2f cm', py));
        set(hZText, 'String', sprintf('Z = %0.1f cm', pz));
        set(hPhiText, 'String', sprintf('φ = %0.0f°', phi * 180 / pi));
        set(hGammaText, 'String', sprintf('γ = %0.0f°', gamma * 180 / pi));
    
        if get(hArmConfig1, 'Value') == 1
            k_Arm1 = -1;
        else k_Arm1 = 1;
        end
        
        if get(hArmConfig3, 'Value') == 1
            k_Arm3 = -1;
        else k_Arm3 = 1;
        end
        
        % calculate inverse kinematics
        jointarray = ik_Youbot(px,py,pz,phi,gamma,k_Arm1,k_Arm3);
        
        % solution valid check
        if numel(jointarray)~=5
            return
        end
%         solution_valid = isSolutionValid(jointarray);
        
%         if solution_valid        
%             % apply 
%             robot.setJoins(jointarray(1), jointarray(2), jointarray(3), jointarray(4), jointarray(5));
%         else
%             errordlg('Inverse Kinematics solver failed!');
%         end
        robot.setJoins(jointarray(1), jointarray(2), jointarray(3), jointarray(4), jointarray(5));
    end

    function [theta] = ik_Youbot(gx,gy,gz,gphi,ggamma,jointconfig1,jointconfig3)
        T_B_T = T_shift(gx, gy, gz) * T_rot('xz', gphi, ggamma);  
%         T_B_T = T_shift(gx, gy, gz);
		t_goal.place(T_B_T);
        
        % first joint
        j1 = atan2(gy,gx);
        if jointconfig1 == 1
            pt_x = sqrt(gx^2 + gy^2)-a1;            
        else
            pt_x = sqrt(gx^2 + gy^2)+a1;              
            
            if j1<0
                j1= j1+pi;
            else
                j1= j1-pi;
            end
        end
        pt_y = gz-d1;
        
        % check if the goal positon can be reached
        if sqrt(pt_x^2+pt_y^2)>(a2+a3+d5)
            errordlg('Out of work space!');
            theta=[];
            return
        end
        
        % third joint
        pw_x = pt_x - d5*cos(gphi);
        pw_y = pt_y - d5*sin(gphi);
        
        % check if the goal position can be reached at all
        if sqrt(pw_x^2 + pw_y^2)>(a2+a3) || sqrt(pw_x^2 + pw_y^2)<abs(a2-a3)
            errordlg('goal position cannot be reached!');
            theta=[];
            return
        end
        
        alpha = atan2(pw_y, pw_x);
        
        j3_cos = (pw_x^2 + pw_y^2 - a2^2 - a3^2)/(2*a2*a3);
        if j3_cos > 0.9999999
            j3 = 0;
        elseif j3_cos < -0.9999999
            j3 = pi;
        else
            j3 = atan2(sqrt(1-j3_cos^2), j3_cos);
        end
        j3 = jointconfig3*j3;
        
        % second joint
        beta_cos = (pw_x^2 + pw_y^2 + a2^2 - a3^2)/(2*a2*sqrt(pw_x^2 + pw_y^2));
        if beta_cos > 0.9999999
            beta = 0;
        elseif beta_cos < -0.9999999
            beta = pi;
        else
            beta = atan2(sqrt(1-beta_cos^2), beta_cos);
        end
        if j3<0
            j2 = alpha + beta;
        else
            j2 = alpha - beta;
        end
        
        % fourth joint determines the pitch of the gripper
        j4 = gphi-j2-j3;
        
        % fifth joint, determines the roll of the gripper (= wrist angle)
        j5_cos = T_B_T(2,2)*cos(j1)-T_B_T(12)*sin(j1);
        if j5_cos > 0.9999999
            j5 = 0;
        elseif j3_cos < -0.9999999
            j5 = pi;
        else
            j5 = atan2((T_B_T(2,1)*cos(j1)-T_B_T(1,1)*sin(j1)), (T_B_T(2,2)*cos(j1)-T_B_T(12)*sin(j1)));
        end  
        
        if jointconfig1 == -1
            j2 = pi-j2;
            j3 = -j3;
            j4 = -j4;
            j5 = -j5;
        end
        
        theta =[j1, j2, j3, j4, j5];
    end
    
    function closeHandler(varargin)
		run = false;
		delete(ax);	
		if ~spnav('close')
			warning('Closing Space Navigator device failed');
		end
	end

    function solution_valid = isSolutionValid(theta)
%         global max_angles min_angles
        
        solution_valid = true;
        if numel(theta)~=5
            solution_valid = false;
            return
        end
        for i=1:5
            if theta(i)<min_angles(i) ||theta(i)>max_angles(i)
                solution_valid = false;
                return
            end
        end
    end
end