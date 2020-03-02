clc;close all
clear all;
for type=1:2
k=0;
for mm=3:9
    for dd=1:31
        if (mm==4||mm==6||mm==9)&&dd==31
            continue
        end
        for hh=11:12:11%11-20/23-08
            name=['Z_UPAR_I_54511_2018',num2str(mm,'%02d'),num2str(dd,'%02d'),num2str(hh,'%02d'),'*_O_TEMP-L.txt'];
            file=dir(fullfile('J:\Z9010\tlogp\2018',name));
            fid=fopen(fullfile('J:\Z9010\tlogp\2018',file.name),'r');k=k+1;
            if fid<=0
                Ri(1:3000,k)=NaN;
                Temp(1:3000,k)=NaN;
                continue
            else
                jpg=['2018',num2str(mm,'%02d'),num2str(dd,'%02d'),'.',num2str(hh+1,'%02d'),'000.jpg'];
                id_jpg=fopen(fullfile('J:\Z9010\X_radar_jpg',jpg),'rb');
                if id_jpg>0
                    fclose(id_jpg);
                else
                    Ri(1:3000,k)=NaN;
                    Temp(1:3000,k)=NaN;
                    continue
                end
            end
            if type==1
            %% %分钟数据
                [tmp_1, ~, ~] = importdata(fullfile('J:\Z9010\tlogp\2018',file.name),'\t');
                tmp_2=strfind(tmp_1,'MINUTE');tmp_2(cellfun(@isempty,tmp_2)) = {0};
                mark=find(cell2mat(tmp_2)~=0);clearvars tmp_1 tmp_2;textscan(fid,'%s',2,'HeaderLines',mark-1);p=0;
                while 1
                    tmp_1=textscan(fid,'%s',9);tmp_2=cellfun(@str2num,tmp_1{1,1},'un',0); mark=cellfun(@isempty,tmp_2);
                    txtdata(~mark)=cell2mat(tmp_2);txtdata(mark)=NaN;
                    if any(isnan(txtdata)) 
                        continue
                    end
                    if txtdata(7)>5000
                        sonde(k).time=['2018',num2str(mm,'%02d'),num2str(dd,'%02d'),num2str(hh,'%02d')];
                        break
                    else
                        p=p+1;
                        sonde(k).data(p,1:9)=txtdata;
                        %1时间/2温度/3气压/4相对湿度/5风向/6风速/7高度/8经度偏差/9纬度偏差
                    end
                end
            elseif type==2
            %% %秒数据
                textscan(fid,'%s',2,'HeaderLines',5);p=1;
                while 1
                    tmp_1=textscan(fid,'%s',12);
                    tmp_2=cellfun(@str2num,tmp_1{1,1},'un',0); mark=cellfun(@isempty,tmp_2);
                    txtdata(~mark)=cell2mat(tmp_2);txtdata(mark)=NaN;
                    if any(isnan(txtdata))
                        continue
                    end
                    %1相对时间/2温度/3气压/4相对湿度/5仰角/6方位/7距离km/8经度偏差/9纬度偏差/10风向/11风速/12高度
                    if txtdata(12)>5000
                        sonde(k).time=['2018',num2str(mm,'%02d'),num2str(dd,'%02d'),num2str(hh,'%02d')];
                        break
                    else
                        p=p+1;
                        sonde(k).data(p,1:9)=[txtdata(1:4),txtdata(10:12),txtdata(8:9)];
                        %1时间/2温度/3气压/4相对湿度/5风向/6风速/7高度/8经度偏差/9纬度偏差
                    end
                end
            end
            %%
            fclose(fid);clearvars tmp_1 tmp_2 mark txtdata p
            for i=1.5:0.5:size(sonde(k).data,1)-0.5
                if rem(i,1)==0
                    z1=i-1;z2=i+1;
                else
                    z1=floor(i);z2=ceil(i);
                end
                tem1=sonde(k).data(z1,2);tem2=sonde(k).data(z2,2);
                pre1=sonde(k).data(z1,3);pre2=sonde(k).data(z2,3);
                hum1=sonde(k).data(z1,4);hum2=sonde(k).data(z2,4);
                dir1=sonde(k).data(z1,5);dir2=sonde(k).data(z2,5);
                vel1=sonde(k).data(z1,6);vel2=sonde(k).data(z2,6);
                alt1=sonde(k).data(z1,7);alt2=sonde(k).data(z2,7);
                sonde(k).Ri(i*2-1)=funRi(tem1,tem2,pre1,pre2,hum1,hum2,dir1,dir2,vel1,vel2,alt1,alt2);
                sonde(k).Temp(i*2-1)=(tem2-tem1)/(alt2-alt1)*100;
                sonde(k).Zi(i*2-1)=(alt1+alt2)/2;
            end
            tmp_1=sonde(k).Zi;tmp_2=sonde(k).Ri;tmp_3=sonde(k).Temp;
            tmp_x=tmp_1(~isnan(tmp_2)&abs(tmp_2)~=Inf);tmp_y=tmp_2(~isnan(tmp_2)&abs(tmp_2)~=Inf);tmp_z=tmp_3(~isnan(tmp_2)&abs(tmp_2)~=Inf);
            [tmp_x,index]=sort(tmp_x);
            Ri(1:3000,k)=interp1(tmp_x+rand(1,size(tmp_x,2)).*1e-3,tmp_y(index),1:3000,'linear')';
            Temp(1:3000,k)=interp1(tmp_x+rand(1,size(tmp_x,2)).*1e-3,tmp_z(index),1:3000,'linear')';
            clearvars tmp_1 tmp_2 tmp_3 tmp_x tmp_y tmp_y
        end
    end
end
figure(10)
subplot(3,1,type)
surf(Ri,'edgecolor','none'),set(gca, 'CLim', [-1.4 0.4]),colorbar,colormap('jet'),view(2)
set(gca,'XTick',[1,32,62,93,123,154,185])
set(gca,'XTickLabel',{'Mar','Apr','May','June','July','Aug','Sep'})
axis([1 214 1 3000])
figure(11)
subplot(3,1,type)
surf(Temp,'edgecolor','none'),set(gca, 'CLim', [-1 0.2]),colorbar,colormap('jet'),view(2)
set(gca,'XTick',[1,32,62,93,123,154,185])
set(gca,'XTickLabel',{'Mar','Apr','May','June','July','Aug','Sep'})
axis([1 214 1 3000])
end
for i=1:214
    Ri_smooth(1:3000,i)=smooth(Ri(1:3000,i),50);
    Temp_smooth(1:3000,i)=smooth(Temp(1:3000,i),50);
end
figure(10)
subplot(3,1,3)
surf(Ri_smooth,'edgecolor','none'),set(gca, 'CLim', [-1.4 0.4]),colorbar,colormap('jet'),view(2)
set(gca,'XTick',[1,32,62,93,123,154,185])
set(gca,'XTickLabel',{'Mar','Apr','May','June','July','Aug','Sep'})
axis([1 214 1 3000])
figure(11)
subplot(3,1,3)
surf(Temp_smooth,'edgecolor','none'),set(gca, 'CLim', [-1 0.2]),colorbar,colormap('jet'),view(2)
set(gca,'XTick',[1,32,62,93,123,154,185])
set(gca,'XTickLabel',{'Mar','Apr','May','June','July','Aug','Sep'})
axis([1 214 1 3000])

function Ri=funRi(tem1,tem2,pre1,pre2,hum1,hum2,dir1,dir2,vel1,vel2,alt1,alt2)
    r1=mixing_ratio(tem1,pre1,hum1);r2=mixing_ratio(tem2,pre2,hum2);%混合比
    theta1=(tem1+273.15)*((1000/pre1)^0.286);theta2=(tem2+273.15)*((1000/pre2)^0.286);%位温
    theta_v1=theta1*(1+0.61*r1-0);theta_v2=theta2*(1+0.61*r2-0);%虚位温
    u1=cosd(dir1)*vel1;v1=sind(dir1)*vel1;u2=cosd(dir2)*vel2;v2=sind(dir2)*vel2;
    z=sqrt(alt1*alt2);
    Ri_1=9.8/(theta_v1+theta_v1)*0.5;%第一项
    Ri_2=(theta_v1-theta_v2)/(z*log(alt2/alt1));%第二项
    Ri_3=((u2-u1)/(z*log(alt2/alt1)))^2+((v2-v1)/(z*log(alt2/alt1)))^2;%第三项
    Ri=Ri_1*Ri_2/Ri_3;
end

function s=mixing_ratio(t,p,f)
    E=6.11*10^(7.5*t/(237.15+t));%饱和水汽压E(玛格努斯经验公式)
    e=f*E/100;%相对湿度f/水汽压e
    s=0.622*e/(p-e);%大气压力p/混合比s
end
