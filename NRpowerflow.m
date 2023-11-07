function [PQ,nPQ,P_gen_cal,J,V_mag,V_Delta]= NRpowerflow(S_Base,No_of_Buses,No_of_Lines,Bus_data,Line_data,P_input)
%  read grid data from file
file_name='ieee14cdf.txt';
[S_Base,No_of_Buses,No_of_Lines,Bus_data,Line_data]=Read_data(file_name);
 V_mag_final=Bus_data(:,5); %magnitude of final voltage in p.u.
 V_ang_final=Bus_data(:,6); % change angle of final voltage from degrees to radians.
 P_load=Bus_data(:,7)/S_Base; %active power of Load in p.u.
 Q_load=Bus_data(:,8)/S_Base; %reactive power of Load in p.u.
 P_gen=Bus_data(:,9)/S_Base; %active power of generation in p.u.
 Q_gen=Bus_data(:,10)/S_Base; %reactive power of genertion in p.u.
 Qmax = Bus_data(:,13)/S_Base;     % Maximum Reactive Power Limit
 Qmin = Bus_data(:,14)/S_Base;     % Minimum Reactive Power Limit
if P_input >0
P_gen(2)=P_input;
end
 
%% type of buses
  slack=find(Bus_data(:,4)==3); %slack bus
  PQ=find(Bus_data(:,4)==0|Bus_data (:,4) == 1); %PQ bus
  PV=find(Bus_data(:,4)==2); %PV bus
 nslack=length(slack);
 nPQ=length(PQ);
 nPV=length(PV);
  %% form Y_matrix
 [Y_mat,Theta,Y_mag,B,G]=Y_bus(Bus_data,Line_data,No_of_Buses,No_of_Lines); %form Y_matrix
 
 %% initialize parameters

V_mag=Bus_data(:,12); %initial voltage
V_mag(~V_mag) = 1; % replace all 0 with 1 for voltage magnitude
V_Delta=zeros(No_of_Buses,1); %initial angle
 P_sch=P_gen-P_load; %net power scheduled at a bus
 Q_sch=Q_gen-Q_load;
 dif_Voltage=zeros(No_of_Buses-1+nPQ,1);
 
 %% Newton-Raphson calculation start
 
 tol_max=0.01; % iteration tolerance of the solution
 iter=0; %times of iteration
 tol=1; %initial value of tol
 
 while (tol>tol_max)
    [P_cal,Q_cal]=Cal_PQ(V_mag,Y_mag,Theta,V_Delta,No_of_Buses); %calculate the power at buses     
    [dif_PQ]=differen_PQ(P_sch,Q_sch,P_cal,Q_cal,PQ,nPQ); % mismatches vector
    [J]=Jacobian_Matrix(V_mag,P_cal,Q_cal,Y_mag,Theta, V_Delta,No_of_Buses,PQ,nPQ,B,G); %call the Jacobian matrix
    dif_Voltage=inv(J)*dif_PQ; %get correction vector
%     [dif_Voltage]=LU_factor_PQ(J,dif_PQ);
   
    dif_D=dif_Voltage(1:No_of_Buses-1); % angle correction vector
    dif_V=dif_Voltage(No_of_Buses:end); % magnitude correction vector
    
    V_Delta(2:end)=V_Delta(2:end)+dif_D; %correct the results, angle and voltage
    V_mag(PQ)=V_mag(PQ)+dif_V;
    tol=max(abs(dif_PQ));
    iter=iter+1;
 end
    if iter>5
        disp('bad, not converge');
    else
        V_result=[V_mag,rad2deg(V_Delta)];        
    end  
% %% verify the calculation results
% if max(V_result-[V_mag_final,V_ang_final])<=0.1
%     fprintf('Congratulation,converge!, times of iteration=%d.\n',iter);
% else
%     disp('converge, but results are not correct, please go back to check!');
% end
P_gen_cal=P_cal+P_load;
Q_gen_cal=Q_cal+Q_load;
end


 
 
  
 
 
 
 
 
    
 
 
 
 
 
         
         
         






    
