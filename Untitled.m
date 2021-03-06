function [T_h_out,T_c_out] = Untitled(N)
   %inlet conditions
    P_h = 400;
    P_c = 100; 
    m_h = 5.6 * 1e-6;
    m_c = 5.6 * 1e-6;
    R = 'helium';
    T_h_in = 305;
    T_c_in = 74;
    %N = 200;

%number of grids ,allocate space for matrix
%cp_h = zeros(1,N);
%cp_c = zeros(1,N);
h_h = zeros(1,N+1);
h_c = zeros(1,N+1);
T_h = zeros(1,N+1);
T_c = zeros(1,N+1);
T_w= zeros(1,N+2);
h_T_h = zeros(1,N+1);
h_T_c = zeros(1,N+1);
Q_dot_hw= zeros(1,N+1);
Q_dot_wc= zeros(1,N+1);
Q_dot_con= zeros(1,N+1);
T_h_ave= zeros(1,N+1);
T_c_ave= zeros(1,N+1);
Nu_c= zeros(1,N+1);
Nu_h= zeros(1,N+1);
Re_c= zeros(1,N+1);
Re_h= zeros(1,N+1);
mu_c= zeros(1,N+1);
mu_h= zeros(1,N+1);
k_c= zeros(1,N+1);
k_h= zeros(1,N+1);
rho_c= zeros(1,N+1);
rho_h= zeros(1,N+1);
P_c= zeros(1,N+1);
P_h= zeros(1,N+1);
u_c= zeros(1,N+1);
u_h= zeros(1,N+1);
dp_h= zeros(1,N+1);
dp_c= zeros(1,N+1);
T_inter = zeros(1,N+1);
lamda_w_m= zeros(1,N+1);
k_glass = zeros(1,N+1);
T_h_error = zeros(1,N);
T_c_error = zeros(1,N);
T_w_error = zeros(1,N);

%perfored-plate geomtry parameters
d_p = 2.25 * 1e-3; 		
h_p = 1 * 1e-3;			
W=27*1e-3;
Height=1*1e-3;	
Length=69*1e-3;
thick_wall=0.2*1e-3;
thick_cover=0.4*1e-3;	
N_p = 250;
delta_L = Length/N;

%heat conduction area
A_con = (W+thick_cover*2)*(Height*2+thick_cover*2+thick_wall)-2*W*Height;

% heat convection area
deltaA_h=(Length*W+N_p*pi*d_p*h_p-N_p*pi*d_p^2/4)/N;
deltaA_c=deltaA_h;

%hydraulic diameter
V_fluid=W*Height*Length-N_p*pi*d_p^2/4*h_p;
V_all=W*Height*Length;
porosity=V_fluid/V_all;
A_wetted=2*(Height*Length+W*Length)+N_p*pi*d_p*h_p-2*N_p*pi*d_p^2/4;
D_h_h=4*porosity*V_fluid/A_wetted;
D_h_c=D_h_h;

%channel section area
A_h=W*Height*porosity;
A_c=A_h;

%SiO2 conductivity
x = xlsread('E:\MATLAB\R2019a\platecfhx\SiO2.xlsx',1,'A3:A398');
y = xlsread('E:\MATLAB\R2019a\platecfhx\SiO2.xlsx',1,'B3:B398');

%boundary
T_h(1)=T_h_in;
T_c(N+1)=T_c_in;
h_c(N+1)=refpropm('H','T',T_c_in,'P',P_c,R);
h_h(1)=refpropm('H','T',T_h_in,'P',P_h,R);
T_w(1)=T_h(1);
T_w(N+2)=T_c(N+1);

for i=1:N+1
    T_h(i) = T_h_in - (T_h_in - T_c_in) * (i-1)/N;
    T_c(i) = T_h(i);
end

for i=1:N
    T_w(i+1) = (T_h(i) + T_h(i+1)) / 2;
    h_h(i+1) = refpropm('H','T',T_h(i+1),'P',P_h,R);
    h_c(i) = refpropm('H','T',T_c(i),'P',P_c,R);
end

eps = 0.001;
j = 0;
while 1
    for i = 1:N
       T_h_ave(i) = (T_h(i) + T_h(i+1)) / 2;
       T_c_ave(i) = (T_c(i) + T_c(i+1)) / 2;
       T_h_old = T_h(i+1);
       T_c_old = T_c(i);
       T_w_old = T_w(i+1);
       
       %Physical properties rho-density, k-thermal conductivity, mu-viscosity,
       %cp-Specific heat e
       
       k_h(i) = refpropm('L','T',T_h_ave(i),'P',P_h,R);
       k_c(i) = refpropm('L','T',T_c_ave(i),'P',P_c,R);
       mu_h(i) = refpropm('V','T',T_h_ave(i),'P',P_h,R);
       mu_c(i) = refpropm('V','T',T_c_ave(i),'P',P_c,R); 
       cp_h(i) = refpropm('C','T',T_h_ave(i),'P',P_h,R);
       cp_c(i) = refpropm('C','T',T_c_ave(i),'P',P_c,R);
      
       
       %Characteristics 
       rho_h(i) = refpropm('D','T',T_h_ave(i),'P',P_h,R);
       rho_c(i) = refpropm('D','T',T_c_ave(i),'P',P_c,R);
       Nu_c(i) = 4.11;
	   Nu_h(i) = 4.11;
       u_c(i)=m_c/(A_c*rho_c(i));
	   u_h(i)=m_h/(A_h*rho_h(i));
	   Re_c(i) = rho_c(i)*u_c(i)*D_h_h/mu_c(i);
	   Re_h(i) = rho_h(i)*u_h(i)*D_h_c/mu_h(i);
	   h_T_c(i)=Nu_c(i)*k_c(i)/D_h_c;
	   h_T_h(i)=Nu_h(i)*k_h(i)/D_h_h;
	   dp_h(i) = 69.31*Re_h(i)^(-0.87)*rho_h(i)*u_h(i)^2*delta_L/D_h_h;
	   dp_c(i) = 69.31*Re_c(i)^(-0.87)*rho_c(i)*u_c(i)^2*delta_L/D_h_c;
       
       %convection heat transfer
       h_T_h(i) = Nu_h(i) * k_h(i) / d_p;
       h_T_c(i) = Nu_c(i) * k_c(i) / d_p;

       Q_dot_hw(i) = h_T_h(i) * deltaA_h * (T_h_ave(i)-T_w(i+1));
       Q_dot_wc(i) = h_T_c(i) * deltaA_c * (T_w(i+1)-T_c_ave(i));

       %update temperature for T_h(i+1), T_c(i), T_w(i+1);
       %T_h(i+1) = T_h(i) - Q_dot_hw(i)/m_h/cp_h(i);
       %T_c(i) = T_c(i+1) + Q_dot_wc(i)/m_c/cp_c(i);
        h_h(i+1) = h_h(i) - Q_dot_hw(i)/m_h;
        h_c(i) = h_c(i+1) + Q_dot_wc(i)/m_c;
        T_h(i+1) = refpropm('T','H',h_h(i+1),'P',P_h,R);
        T_c(i) = refpropm('T','H',h_c(i),'P',P_c,R);
     
       %heat conduction in the heat exchanger
       T_inter(i)= (T_w(i)+T_w(i+1))/2; 
       T_inter(N+1) = (T_w(N+1)+T_w(N+2))/2;
       k_glass(i) = interp1(x,y,T_inter(i),'linear');
       lamda_w_m(i) = k_glass(i);
     
        if i == 1
          Q_dot_con(1) = 2*lamda_w_m(1)*A_con*(T_w(1)-T_w(2))/delta_L;
                
        else
        Q_dot_con(i) = (lamda_w_m(i+1)*A_con)*(T_w(i)-T_w(i+1))/delta_L;
        lamda_w_m(i+1) = k_glass(i+1);
        Q_dot_con(N+1) = 2*(lamda_w_m(N+1)*A_con)*(T_w(N+1)-T_w(N+2))/delta_L;
        end

        
       %heat convection for N grids
       if i==1
           T_w(i+1) = (delta_L * (Q_dot_hw(i)-Q_dot_wc(i))/A_con + 2*k_glass(i)*T_w(i) + k_glass(i+1)*T_w(i+2))/(2*k_glass(i)+k_glass(i+1));
       elseif i==N
           T_w(i+1) = (delta_L * (Q_dot_hw(i)-Q_dot_wc(i))/A_con + k_glass(i)*T_w(i) + 2*k_glass(i+1)*T_w(i+2))/(k_glass(i)+2*k_glass(i+1));
       else
           T_w(i+1) = (delta_L * (Q_dot_hw(i)-Q_dot_wc(i))/A_con + k_glass(i)*T_w(i) + k_glass(i+1)*T_w(i+2))/(k_glass(i)+k_glass(i+1));
       end

       T_h_error(i) = abs(T_h(i+1)-T_h_old);
       T_c_error(i) = abs(T_c(i)-T_c_old);
       T_w_error(i) = abs(T_w(i+1)-T_w_old);

    end
    T_w(1) = (T_h_in+T_c(1))/2;
    T_w(N+2) = (T_h(N+1)+T_c_in)/2;
    
    max_th = max(T_h_error);
    max_tc = max(T_c_error);
    max_tw = max(T_w_error);
    M_error = [max_th,max_tc,max_tw];
    max_error = max(M_error)
    j = j+1

    if(max_error < eps)
        break;
    end

end

dx = linspace(0,1,N+1);
plot(dx,T_h,dx,T_c);
T_h_out = T_h(N+1)
T_c_out = T_c(1)
end

