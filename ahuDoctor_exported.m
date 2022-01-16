classdef ahuDoctor_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        AHU_fault_detector             matlab.ui.Figure
        ahuDoctorPanel                 matlab.ui.container.Panel
        Panel_2                        matlab.ui.container.Panel
        GeneratereportButton           matlab.ui.control.Button
        HealthIndexEF                  matlab.ui.control.NumericEditField
        SystemhealthindexButton        matlab.ui.control.Button
        FaultsPanel                    matlab.ui.container.Panel
        SAPRestEF                      matlab.ui.control.NumericEditField
        SATRestEF                      matlab.ui.control.NumericEditField
        CCEF                           matlab.ui.control.NumericEditField
        MoOEF                          matlab.ui.control.NumericEditField
        SoOEF                          matlab.ui.control.NumericEditField
        VAVBoxEF                       matlab.ui.control.NumericEditField
        TempFlowEF                     matlab.ui.control.NumericEditField
        HCEF                           matlab.ui.control.NumericEditField
        MBEF                           matlab.ui.control.NumericEditField
        DetectsoftfaultsPanel          matlab.ui.container.Panel
        Panel                          matlab.ui.container.Panel
        DuctstaticpressuresetpointButton  matlab.ui.control.Button
        SupplyairtemperaturesetpointButton  matlab.ui.control.Button
        ModeofoperationButton          matlab.ui.control.Button
        StateofoperationButton         matlab.ui.control.Button
        UserinputsPanel                matlab.ui.container.Panel
        Minimummixingboxdamperpositionsetpointeg02EditField  matlab.ui.control.NumericEditField
        Minimummixingboxdamperpositionsetpointeg02EditFieldLabel  matlab.ui.control.Label
        SeasonalavailabilityEditField  matlab.ui.control.NumericEditField
        SeasonalavailabilityEditFieldLabel  matlab.ui.control.Label
        TextArea_2                     matlab.ui.control.TextArea
        DetecthardfaultsPanel          matlab.ui.container.Panel
        ZonelevelPanel                 matlab.ui.container.Panel
        toEditField                    matlab.ui.control.NumericEditField
        toEditFieldLabel               matlab.ui.control.Label
        SelectzonenumberfromEditField  matlab.ui.control.NumericEditField
        SelectzonenumberfromEditFieldLabel  matlab.ui.control.Label
        CheckButton                    matlab.ui.control.Button
        ZonenumberEditField            matlab.ui.control.NumericEditField
        ZonenumberEditFieldLabel       matlab.ui.control.Label
        VAVboxButton                   matlab.ui.control.Button
        TemperatureandairflowButton    matlab.ui.control.Button
        SystemlevelPanel               matlab.ui.container.Panel
        CoolingcoilButton              matlab.ui.control.Button
        HeatingcoilButton              matlab.ui.control.Button
        MixingboxButton                matlab.ui.control.Button
        LoaddataPanel                  matlab.ui.container.Panel
        ReaddataButton                 matlab.ui.control.Button
        VAVzonesButton                 matlab.ui.control.Button
        AHUButton                      matlab.ui.control.Button
    end


    properties (Access = private)
        AHUfile  % Excel file uploaded for AHU
        VAVfolder % Folder containing VAV zone files
        VAVfiles % VAV files directory
        fileNumber % sequential number of vav files
        fullName % VAV Excel file full name (filePath,fileName)
        tRd % Raw data from AHU table read
        t  % matlab date time
        tSa % supply air temperature (degC)
        tRa % return air temperature (degC)
        tOa % outdoor air temperature (degC)
        sHc % heating coil valve (%)
        sCc % cooling coil valve (%)
        sOa % mixing box damper (%)
        sFan % fan status (%)
        pSa % supply air pressure (Pa)
        tIn % vav zone indoor temperature (degC)
        qFlo % vav airflow rate (L/s)
        qFloSp % vav airflow rate setpoint (L/s)
        sDmp % vav terminal damper (%)
        mdlDmp % Damper position mixing box model prediction
        gofDmp % Good of fitness of mixing box model
        mdlDmpCoeff % Mixing box model coefficients [a b c]
        mdlHtgClCoeff % Heating coil model coefficients [a b c]
        mdlClgClCoeff % Cooling coil model coefficients [a b c]
        seasonalAvailability % Heating and cooling seasonal availability
        zn % Selected zone number for zone vav box fault detection
        fig % UI Figure in a new window
        fig1
        fig2
        fig3
        fig4
        fig5
        fig6
        fig7
        fig8
        fig9
        uiax % ui axes for ui figure
        sOaFaults % mixing box damper faults
        sHcFault % heating coil valve fault
        sCcFault % cooling coil valve fault
        fracFaultyZone % air and temperature control faulty zone fraction
        fracFaultyVav  % vav damper faulty zone fraction
        VAVFaultyZones % a list of faulty vav zones excel file name
        VAVFaultyZonesNumber % a list of faulty vav zones sequential number
        TempFlowFaultyZones % a list of faulty temp and flow zones excel file name
        TempFlowFaultyZonesNumber % a list of faulty temp and flow zones sequential number
        SoOFaults % state of operation fault 
        MoOFault % mode of operation fault 
        tSaFault % supply air temperature setpoint reset fault
        pSaFault % supply air pressure setpoint reset fault
        kpi % System health index (%)
        
    end


    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            app.AHU_fault_detector.Position = [5 20 301 815]; % Main UIFigure position [left bottom width height]
        end

        % Button pushed function: AHUButton
        function AHUButtonPushed(app, event)
            [file,filepath,filter] = uigetfile({'*ahu*'},'Select AHU Excel file');
          app.AHUfile = fullfile(filepath, file);
          
          f = uifigure('Position',[500 500 420 180]); % [left bottom width height]
        mess = ['File ',file,' successfully selected!'];
        title = "Success";    
        uialert(f, mess, title,'Icon','success','CloseFcn',@(h,e) close(f));
        
        drawnow;
          figure(app.AHU_fault_detector)
          
        end

        % Button pushed function: VAVzonesButton
        function VAVzonesButtonPushed(app, event)
           [FileName,PathName] = uigetfile('*.xlsx', 'Open file','MultiSelect','on');
            app.VAVfiles = string(FileName);
            app.fileNumber = 1:length(app.VAVfiles);
            app.fullName = string(fullfile(PathName, FileName));
    
            f = uifigure('Position',[500 500 420 180]); % [left bottom width height]
            mess = ['VAV files successfully selected!'];
            title = "Success";    
            uialert(f, mess, title,'Icon','success','CloseFcn',@(h,e) close(f));
        
            drawnow;
            figure(app.AHU_fault_detector)
   
        end

        % Button pushed function: ReaddataButton
        function ReaddataButtonPushed(app, event)
         WB = waitbar(0, 'Importing data', 'Name', 'xlsread files progress',...
       'CreateCancelBtn', 'setappdata(gcbf,     ''canceling'', 1)');
        setappdata(WB,'canceling',0);
   
        % Read data from AHU file
            app.tRd = readtable(app.AHUfile,"Sheet","data");

            app.tRd.Properties.VariableNames{1} = 'dT'; % Datetime
            app.tRd.Properties.VariableNames{2} = 'sAt'; % Supply air temperature (deg.C)
            app.tRd.Properties.VariableNames{3} = 'rAt'; % Return air temperature (deg.C)
            app.tRd.Properties.VariableNames{4} = 'oAt'; % Outdoor air temperature (deg.C)
            app.tRd.Properties.VariableNames{5} = 'sHc'; % Heating coil valve position (%)
            app.tRd.Properties.VariableNames{6} = 'sCc'; % Cooling coil valve position (%)
            app.tRd.Properties.VariableNames{7} = 'sMb'; % Mixing box damper position (%)
            app.tRd.Properties.VariableNames{8} = 'sFan'; % Fan state (%)
            app.tRd.Properties.VariableNames{9} = 'pSa'; % Supply air pressire (Pa)
       
            app.t = datenum(app.tRd.dT); % matlab date time
            app.tSa = app.tRd.sAt; % supply air temperature (degC)
            app.tRa = app.tRd.rAt; % return air temperature (degC)
            app.tOa = app.tRd.oAt; % outdoor air temperature (degC)
            app.sHc = app.tRd.sHc; % heating coil valve (%)
            app.sCc = app.tRd.sCc; % cooling coil valve (%)
            app.sOa = app.tRd.sMb; % mixing box damper (%)
            app.sFan = app.tRd.sFan; % fan status (%)
            app.pSa = app.tRd.pSa; % supply air pressure (Pa)
            
        % Read data from VAV zone files      
                   
        for k=1:length(app.VAVfiles)
            zone =readtable(app.fullName(k),"Sheet","data");

            zone.Properties.VariableNames{1} = 'dT'; % Date time
            zone.Properties.VariableNames{2} = 'zAt'; % Zone air temp (degC)
            zone.Properties.VariableNames{3} = 'aFr'; % % Airflow rate (L/s)
            zone.Properties.VariableNames{4} = 'aFrSp'; % Airflow rate setpoint (L/s)
            zone.Properties.VariableNames{5} = 'sVAVDmp';  % Vav terminal damper (%)

            app.tIn(:,k) = zone.zAt; % indoor temperature (degC)
            app.qFlo(:,k) = zone.aFr; % airflow rate (L/s)
            app.qFloSp(:,k) = zone.aFrSp; % airflow rate setpoint (L/s)
            app.sDmp(:,k) = zone.sVAVDmp; % vav terminal damper (%)

             waitbar(k/length(app.VAVfiles),WB, sprintf('Reading VAV zone .xls file %d of %d', k, length(app.VAVfiles)));
                if getappdata(WB,'canceling')
                 break
                end
        end
      
        app.toEditField.Value = length(app.VAVfiles);
            
        delete(WB)
        
        f = uifigure('Position',[500 500 420 180]); % [left bottom width height]
        mess = ['Data successfully loaded!'];
        title = "Success";    
        uialert(f, mess, title,'Icon','success','CloseFcn',@(h,e) close(f));

        app.toEditField.Value = length(app.VAVfiles);
        
        end

        % Button pushed function: MixingboxButton
        function MixingboxButtonPushed(app, event)
        
            WB = waitbar(0, 'ahuDoctor', 'Name', 'Detect mixing box faults',...
            'CreateCancelBtn', 'setappdata(gcbf,     ''canceling'', 1)');
            setappdata(WB,'canceling',0);
   
        % mixing box mod
        % fan operating hours when heating and cooling are off
        ind = app.sHc == 0 & app.sCc == 0 & app.sFan > 0; 
        tMa(ind,1) = app.tSa(ind,1) - (app.pSa(ind,1)./840);
        fOa = (tMa(ind) - app.tRa(ind))./(app.tOa(ind)-app.tRa(ind)); % outdoor air fraction
        
        waitbar(0.5,WB,'Detect mixing box faults');
        
        handle = app.sOa(ind)/100; % normalize mixing box damper [0 1]
        ft = fittype('c/(1+exp(a*x+b))');
        options = fitoptions(ft);
        options.Robust = 'Bisquare';
        options.Lower = [-20  -20 -20];
        options.Upper = [20    20  20];
        [app.mdlDmp,app.gofDmp] = fit(handle(fOa < 1 & fOa > 0),fOa(fOa < 1 & fOa > 0),ft,options);
        app.mdlDmpCoeff = coeffvalues(app.mdlDmp);
        
        waitbar(0.9,WB,'Detect mixing box faults');
        delete (WB);
        
        % generate a plot defining the behaviour
        
        delete (app.fig)
        delete (app.fig1)
        delete (app.fig2)
        delete (app.fig3)
        
        app.fig1 = uifigure;
        app.fig1.Name = ['Mixing box model'];
        app.fig1.Position = [400 200 400 400]; % %[left bottom width height]in pixels
        set (app.fig1, 'Color', [1 1 1] )
        
 
 % Define plot axes and set their limits
        app.uiax=uiaxes(app.fig1);
        app.uiax.Position = [app.uiax.Position(1:2) [app.fig1.Position(3:4) - 2*app.uiax.Position(1:2)]];
        app.uiax.XLim = [0 1];
        xticks(app.uiax,0:0.2:1)
        app.uiax.YLim = [0 1];
        yticks(app.uiax,0:0.2:1)
        xlabel(app.uiax,'Mixing box damper signal','fontsize',11)
        ylabel(app.uiax,'Outdoor air fraction','fontsize',11)
        set(app.uiax,'TickDir','out');
        app.uiax.Color = [1 1 1];
        app.uiax.BackgroundColor = [1 1 1];
    
    scatter(app.uiax,handle(fOa < 1 & fOa > 0),fOa(fOa < 1 & fOa > 0),8,[0 0 1],...
        'filled','o','MarkerFaceAlpha',.05,'MarkerEdgeAlpha',.05)
    hold(app.uiax,'on');
    plot(app.uiax,(0:0.01:1)',min(app.mdlDmp(0:0.01:1),1),'r','LineWidth',4) 
  
    upperLimit = [0;23;46;68;85;93;97;99;100;100]./100;
    lowerLimit = [0;1;3;5;9;15;25;39;64;100]./100;
    x = linspace(0,1,length(upperLimit));
    
    if sum((app.mdlDmp(x) - lowerLimit) < 0 | (app.mdlDmp(x) - upperLimit) > 0)/length(x) > 0.2
        faults.sOa = 1;
    else
        faults.sOa = 0;
    end
    
    limits = patch(app.uiax,[x' fliplr(x')], [lowerLimit fliplr(upperLimit)], 'g');
    limits.FaceAlpha = 0.1;
    limits.EdgeColor = 'w';
    limits.EdgeAlpha = 0;
    
    app.sOaFaults = faults.sOa;
    app.MBEF.Value = app.sOaFaults;
    
    exportgraphics(app.uiax,'fig1.png','Resolution',600)
  
        end

        % Button pushed function: HeatingcoilButton
        function HeatingcoilButtonPushed(app, event)
    
        WB = waitbar(0, 'ahuDoctor', 'Name', 'Detect heating coil faults',...
            'CreateCancelBtn', 'setappdata(gcbf,     ''canceling'', 1)');
            setappdata(WB,'canceling',0);
            
    % heating coil model
    % fan operating hours when heating is on and cooling is off
        if app.seasonalAvailability == 1
            ind = app.sFan > 0 & app.sHc > 0 & app.sCc == 0 & (month(app.t) > 10 | month(app.t) < 5) & app.sHc < 100;
        else
            ind = app.sFan > 0 & app.sHc > 0 & app.sCc == 0 & app.sHc < 100;
        end
        
    % mixed air estimate using the mixing box model
        tMa = (app.mdlDmp(app.sOa(ind)./100).*app.tOa(ind) + (1-app.mdlDmp(app.sOa(ind)./100)).*app.tRa(ind));
        yHtg = app.tSa(ind) - tMa - app.pSa(ind)./840;
        xHtg = app.sHc(ind)/100;

        waitbar(0.3,WB,'Detect heating coil faults');
        
        ft = fittype('c/(1+exp(a*x+b))');
        options = fitoptions(ft);
        options.Robust = 'Bisquare';
        options.Lower = [-20  -20 -20];
        options.Upper = [20    20  20];
        [mdlHtgCl,gofHtgCl] = fit(xHtg,yHtg,ft,options);
        app.mdlHtgClCoeff = coeffvalues(mdlHtgCl);
        
        waitbar(0.7,WB,'Detect heating coil faults');
        
    % cooling coil model
    % fan operating hours when heating is off and cooling is on
        if app.seasonalAvailability == 1
             ind = app.sFan > 0 & app.sHc == 0 & app.sCc > 0 & (month(app.t) < 10 & month(app.t) > 5) & app.sCc < 100;
        else 
            ind = app.sFan > 0 & app.sHc == 0 & app.sCc > 0 & app.sCc < 100;
        end
    % mixed air estimate using the mixing box model
    tMa = (app.mdlDmp(app.sOa(ind)./100).*app.tOa(ind) + (1-app.mdlDmp(app.sOa(ind)./100)).*app.tRa(ind));
    yClg = app.tSa(ind) - tMa + app.pSa(ind)./840;
    xClg = app.sCc(ind)/100;

    ft = fittype('c/(1+exp(a*x+b))');
    options = fitoptions(ft);
    options.Robust = 'Bisquare';
    options.Lower = [-20  -20 -20];
    options.Upper = [20    20  20];
    [mdlClgCl,gofClgCl] = fit(xClg,yClg,ft,options);
    app.mdlClgClCoeff = coeffvalues(mdlClgCl);

        if (mdlHtgCl(1) - mdlHtgCl(0)) > 5 & mdlHtgCl(0) < 5
            faults.sHc = 0;
        else
        faults.sHc = 1;
        end

        if (mdlClgCl(1) - mdlClgCl(0)) < -5 & mdlClgCl(0) > -5
            faults.sCc = 0;
        else
            faults.sCc = 1;
        end
    
        waitbar(0.9,WB,'Detect heating coil faults');
        delete (WB)
        
        app.sHcFault = faults.sHc;
        app.HCEF.Value = app.sHcFault;

        end

        % Callback function
        function HeatingandcoolingareavailableyearroundCheckBoxValueChanged(app, event)
            value = app.HeatingandcoolingareavailableyearroundCheckBox.Value;
            
                if value == 1
                    app.seasonalAvailability = 0;
                    
                else 
                    app.seasonalAvailability = 1;
                end 
            
        end

        % Callback function
        function WinterButtonPushed(app, event)
        % zone temperature and airflow control faults, winter
            timeOfDay = hour(app.t);
            dayOfWeek = weekday(app.t);
            monthOfYear =  month(app.t);

            ind = find((timeOfDay > 9 & timeOfDay < 17) & (dayOfWeek > 1 & dayOfWeek < 7) & (monthOfYear > 10 | monthOfYear < 5));
            tInWntr = mean(app.tIn(ind,:));
            qFloWntr = app.qFlo(ind,:);
            qFloSpWntr = app.qFloSp(ind,:);
            qFloWntrErr = mean((qFloWntr - qFloSpWntr)./max(qFloSpWntr,1));

            ind = find((timeOfDay > 9 & timeOfDay < 17) & (dayOfWeek > 1 & dayOfWeek < 7) & (monthOfYear < 10 & monthOfYear > 5));
            tInSmr = mean(app.tIn(ind,:));
            qFloSmr = app.qFlo(ind,:);
            qFloSpSmr = app.qFloSp(ind,:);
            qFloSmrErr = mean((qFloSmr - qFloSpSmr)./max(qFloSpSmr,1));   

            ind = (tInWntr < 20 | tInWntr > 25) | (abs(qFloWntrErr) > 0.2) | (tInSmr < 20 | tInSmr > 25) | (abs(qFloSmrErr) > 0.2);
            faults.zone = {app.VAVfiles(ind).name};
            fracFaultyZone = sum(ind)/length(app.qFlo(1,:));

        % generate a plot defining the behaviour
        
        fig = uifigure;
        fig.Name = ['Zone temperature and airflow control'];
        fig.Position = [1200 500 300 300]; % %[left bottom width height]in pixels
        set (fig, 'Color', [1 1 1] )
 
 % Define plot axes and set their limits
        uiax=uiaxes(fig);
        uiax.Position = [uiax.Position(1:2) [fig.Position(3:4) - 2*uiax.Position(1:2)]];
        uiax.XLim = [15 30];
        xticks(uiax,15:3:30)
        uiax.YLim = [-100 100];
        yticks(uiax,-100:20:100);
        xlabel(uiax,'$t_{in}$ $(^{o}C)$','Interpreter','latex')
        uiax.XLabel.FontSize = 10;
        ylabel(uiax,'$\frac{q_{flo} - q_{flo,sp}}{q_{flo,sp}}$ $(\%)\qquad$','Interpreter','latex','fontsize',14)
        uiax.YLabel.FontSize = 10;
        set(uiax,'TickDir','out');  
        uiax.Title.String = 'winter';
        uiax.Color = [1 1 1];
        uiax.BackgroundColor = [1 1 1];
        
    % graphically present the results for winter

    s= scatter(uiax,max(min(tInWntr,30),15),max(min(qFloWntrErr.*100,100),-100),36,'k','filled');
    s.MarkerEdgeAlpha = 0.4;
    s.MarkerFaceAlpha = 0.4;
    hold (uiax,'on')
    
    text(uiax,21.5,15,'normal','FontSize',10)
    text(uiax,16,2,'cold','FontSize',10)
    text(uiax,28,2,'hot','FontSize',10)
    text(uiax,21.5,80,'high flow','FontSize',10)
    text(uiax,21.5,-80,'low flow','FontSize',10)

    % really messed up
    xBox = [15 15 30 30];
    yBox = [-100 100 100 -100];
    s = patch(uiax,xBox, yBox, 'red', 'FaceColor', 'red', 'FaceAlpha', 0.1);        

    % messed up
    xBox = [18 18 27 27];
    yBox = [-50 50 50 -50];
    s = patch(uiax,xBox, yBox, 'yellow', 'FaceColor', 'yellow', 'FaceAlpha', 0.1);     

    % normal
    xBox = [20 20 25 25];
    yBox = [-20 20 20 -20];
    s = patch(uiax,xBox, yBox, 'green', 'FaceColor', 'green', 'FaceAlpha', 0.1);        
    
    
        end

        % Callback function
        function SummerButtonPushed(app, event)
        % zone temperature and airflow control faults, summer
            timeOfDay = hour(app.t);
            dayOfWeek = weekday(app.t);
            monthOfYear =  month(app.t);

            ind = find((timeOfDay > 9 & timeOfDay < 17) & (dayOfWeek > 1 & dayOfWeek < 7) & (monthOfYear > 10 | monthOfYear < 5));
            tInWntr = mean(app.tIn(ind,:));
            qFloWntr = app.qFlo(ind,:);
            qFloSpWntr = app.qFloSp(ind,:);
            qFloWntrErr = mean((qFloWntr - qFloSpWntr)./max(qFloSpWntr,1));

            ind = find((timeOfDay > 9 & timeOfDay < 17) & (dayOfWeek > 1 & dayOfWeek < 7) & (monthOfYear < 10 & monthOfYear > 5));
            tInSmr = mean(app.tIn(ind,:));
            qFloSmr = app.qFlo(ind,:);
            qFloSpSmr = app.qFloSp(ind,:);
            qFloSmrErr = mean((qFloSmr - qFloSpSmr)./max(qFloSpSmr,1));   

            ind = (tInWntr < 20 | tInWntr > 25) | (abs(qFloWntrErr) > 0.2) | (tInSmr < 20 | tInSmr > 25) | (abs(qFloSmrErr) > 0.2);
            faults.zone = {app.VAVfiles(ind).name};
            fracFaultyZone = sum(ind)/length(app.qFlo(1,:));
            
       % generate a plot defining the behaviour
        
        fig = uifigure;
        fig.Name = ['Zone temperature and airflow control'];
        fig.Position = [900 500 300 300]; % %[left bottom width height]in pixels
        set (fig, 'Color', [1 1 1] )
 
       % Define plot axes and set their limits
        uiax=uiaxes(fig);
        uiax.Position = [uiax.Position(1:2) [fig.Position(3:4) - 2*uiax.Position(1:2)]];
        uiax.XLim = [15 30];
        xticks(uiax,15:3:30)
        uiax.YLim = [-100 100];
        yticks(uiax,-100:20:100);
        xlabel(uiax,'$t_{in}$ $(^{o}C)$','Interpreter','latex')
        uiax.XLabel.FontSize = 10;
        ylabel(uiax,'$\frac{q_{flo} - q_{flo,sp}}{q_{flo,sp}}$ $(\%)\qquad$','Interpreter','latex','fontsize',14)
        uiax.YLabel.FontSize = 10;
        set(uiax,'TickDir','out');  
        uiax.Title.String = 'Summer';
        uiax.Color = [1 1 1];
        uiax.BackgroundColor = [1 1 1];
        
        s= scatter(uiax,max(min(tInSmr,30),15),max(min(qFloSmrErr.*100,100),-100),36,'k','filled');
        s.MarkerEdgeAlpha = 0.4;
        s.MarkerFaceAlpha = 0.4;
        hold (uiax,'on')
        
        text(uiax,21.5,15,'normal','FontSize',10)
        text(uiax,16,2,'cold','FontSize',10)
        text(uiax,28,2,'hot','FontSize',10)
        text(uiax,21.5,80,'high flow','FontSize',10)
        text(uiax,21.5,-80,'low flow','FontSize',10)
        
        % really messed up
        xBox = [15 15 30 30];
        yBox = [-100 100 100 -100];
        s = patch(uiax,xBox, yBox, 'red', 'FaceColor', 'red', 'FaceAlpha', 0.1);        

        % messed up
        xBox = [18 18 27 27];
        yBox = [-50 50 50 -50];
        s = patch(uiax,xBox, yBox, 'yellow', 'FaceColor', 'yellow', 'FaceAlpha', 0.1);     

        % normal
        xBox = [20 20 25 25];
        yBox = [-20 20 20 -20];
        s = patch(uiax,xBox, yBox, 'green', 'FaceColor', 'green', 'FaceAlpha', 0.1);        


        end

        % Button pushed function: CheckButton
        function CheckButtonPushed(app, event)
        
        % VAV box fault
        % VAV terminal model
        for i = 1:length(app.sDmp(1,:))
            ind = app.sFan > 0 & app.pSa > 100 & app.qFlo(:,i) > 0;
            X = [(app.sDmp(ind,i)./100).*sqrt(app.pSa(ind)),sqrt(app.pSa(ind))];
            y = [app.qFlo(ind,i)];
            mdl = fitlm(X,y,'Intercept',false);
            mdlVAV.prmtr(:,i) = mdl.Coefficients.Estimate;
            mdlVAV.gof(:,i) = mdl.Rsquared.Ordinary;
    
            yEstLowPres = mdl.Coefficients.Estimate(1)*((linspace(0.2,1,100))'.*15) +...
                          mdl.Coefficients.Estimate(2)*15;
   
            yEstHighPres = mdl.Coefficients.Estimate(1)*((linspace(0.2,1,100))'.*20) +...
                           mdl.Coefficients.Estimate(2)*20;  
        end

            ind = mdlVAV.prmtr(1,:) <= 0;
            faults.vav = {app.VAVfiles(ind)};
            fracFaultyVav = sum(ind)/length(app.qFlo(1,:));
            
       % generate a plot defining the behaviour for a selected zone (zn)
 
            ind = app.sFan > 0 & app.pSa > 100 & app.qFlo(:,i) > 0;
            app.zn = app.ZonenumberEditField.Value; %Selected zone number

            X = [(app.sDmp(ind,app.zn)./100).*sqrt(app.pSa(ind)),sqrt(app.pSa(ind))];
            y = [app.qFlo(ind,app.zn)];
            mdl = fitlm(X,y,'Intercept',false);
            mdlVAV.prmtr(:,app.zn) = mdl.Coefficients.Estimate;
            mdlVAV.gof(:,app.zn) = mdl.Rsquared.Ordinary;
    
            yEstLowPres = mdl.Coefficients.Estimate(1)*((linspace(0.2,1,100))'.*15) +...
                          mdl.Coefficients.Estimate(2)*15;
   
            yEstHighPres = mdl.Coefficients.Estimate(1)*((linspace(0.2,1,100))'.*20) +...
                           mdl.Coefficients.Estimate(2)*20;
        
        delete (app.fig)
        delete (app.fig1)
        delete (app.fig2)
        delete (app.fig3)
        
        app.fig = uifigure;
        app.fig.Name = ['Zone VAV box'];
        app.fig.Position = [400 200 400 400]; % %[left bottom width height]in pixels
        set (app.fig, 'Color', [1 1 1] )
 
      % Define plot axes and set their limits
        app.uiax=uiaxes(app.fig);
        app.uiax.Position = [app.uiax.Position(1:2) [app.fig.Position(3:4) - 2*app.uiax.Position(1:2)]];
        app.uiax.XLim = [0 1];
        xticks(app.uiax,0:0.2:1)
        xlabel(app.uiax,'Damper fraction open','fontsize',11)
        ylabel(app.uiax,'VAV airflow (L/s','fontsize',11)
        set(app.uiax,'TickDir','out');  
        app.uiax.Color = [1 1 1];
        app.uiax.BackgroundColor = [1 1 1];
        
    scatter(app.uiax,(app.sDmp(ind,app.zn)./100),app.qFlo(ind,app.zn),6,[0 0 0],'filled','o','MarkerFaceAlpha',.1,'MarkerEdgeAlpha',.1)
    hold (app.uiax,'on')
    ha = plot(app.uiax,(linspace(0.2,1,100))',max(yEstLowPres,0),'r','LineWidth',2);
    hb = plot(app.uiax,(linspace(0.2,1,100))',max(yEstHighPres,0),'b--','LineWidth',2);  
    legend(app.uiax,[ha hb], {'200 Pa','400 Pa'},'NumColumns',2,'Location','northoutside')
    legend(app.uiax,'boxoff')
    
%}
            
        end

        % Button pushed function: StateofoperationButton
        function StateofoperationButtonPushed(app, event)
        
            WB = waitbar(0, 'ahuDoctor', 'Name', 'Detect state of operation faults',...
            'CreateCancelBtn', 'setappdata(gcbf,     ''canceling'', 1)');
            setappdata(WB,'canceling',0);
            
        sOaMin = app.Minimummixingboxdamperpositionsetpointeg02EditField.Value; % User input 
        
        %% soft faults
        % state of operation
        ind = app.sFan > 0 & app.pSa > 100;
        tMa(ind,1) = app.tSa(ind,1) - (app.pSa(ind)./840);
        
        waitbar(0.5,WB,'Detect state of operation faults');
        
        handle = ((tMa(ind)-app.tRa(ind))./(app.tOa(ind)-app.tRa(ind)));
        handle(handle > 1) = 1.000;
        handle(handle < 0) = 0;
        handle = ((app.mdlDmpCoeff(1,3))./handle) - 1;
        oadIdeal = real((app.tOa(ind) < app.tRa(ind) & app.tOa(ind) < 18).*(log(handle) - app.mdlDmpCoeff(1,2))/app.mdlDmpCoeff(1,1));
        oadIdeal(oadIdeal < sOaMin) = sOaMin;
        oadIdeal(oadIdeal > 1) = 1;
        oadIdeal(isnan(oadIdeal)) = sOaMin;
        
        waitbar(0.9,WB,'Detect state of operation faults');
        delete (WB)
        
        delete (app.fig)
        delete (app.fig1)
        delete (app.fig2)
        delete (app.fig3)
        
     % Fig 1
        app.fig1 = uifigure;
        app.fig1.Name = ['State of operation'];
        app.fig1.Position = [400 560 400 240]; % %[left bottom width height]in pixels
        set (app.fig1, 'Color', [1 1 1] )
 
      
      % Define plot axes and set their limits
        app.uiax=uiaxes(app.fig1);
        app.uiax.Position = [app.uiax.Position(1:2) [app.fig1.Position(3:4) - 2*app.uiax.Position(1:2)]];
        app.uiax.XLim = [-25 35];
        xticks(app.uiax,-25:5:35)
        xlabel(app.uiax,{['Outdoor temperature (' char(176) 'C)']},'fontsize',11)
        app.uiax.YLim = [0 1];
        yticks(app.uiax,0:0.2:1);
        ylabel(app.uiax,'Mixing box damper','fontsize',11)
        set(app.uiax,'TickDir','out');
        app.uiax.Color = [1 1 1];
        app.uiax.BackgroundColor = [1 1 1];
        
        scatter(app.uiax,app.tOa(ind),oadIdeal,8,[0 0 1],'filled','o','MarkerFaceAlpha',.2,'MarkerEdgeAlpha',.2)
        hold (app.uiax,'on')
        scatter(app.uiax,app.tOa(ind),app.sOa(ind)/100,8,[1 0 0],'filled','o','MarkerFaceAlpha',.2,'MarkerEdgeAlpha',.2)
        mae.dmp = mean(abs(oadIdeal - app.sOa(ind)/100));
    
        legend(app.uiax,{'Expected','Measured'},'NumColumns',2,'Location','northoutside')
        legend(app.uiax,'boxoff')
        
        
     % Fig 2
        app.fig2 = uifigure;
        app.fig2.Name = ['State of operation'];
        app.fig2.Position = [400 290 400 240]; % %[left bottom width height]in pixels
        set (app.fig2, 'Color', [1 1 1] )
 
      % Define plot axes and set their limits
        app.uiax=uiaxes(app.fig2);
        app.uiax.Position = [app.uiax.Position(1:2) [app.fig2.Position(3:4) - 2*app.uiax.Position(1:2)]];
        app.uiax.XLim = [-25 35];
        xticks(app.uiax,-25:5:35)
        xlabel(app.uiax,{['Outdoor temperature (' char(176) 'C)']},'fontsize',11)
        app.uiax.YLim = [0 1];
        yticks(app.uiax,0:0.2:1);
        ylabel(app.uiax,'Heating coil','fontsize',11)
        set(app.uiax,'TickDir','out');
        app.uiax.Color = [1 1 1];
        app.uiax.BackgroundColor = [1 1 1];
        
        idealDtHtg = max(app.tSa(ind) - (app.mdlDmp(oadIdeal).*app.tOa(ind) + (1 - app.mdlDmp(oadIdeal)).*app.tRa(ind))-app.pSa(ind)./840,0.01);
        if app.seasonalAvailability == 1
            idealDtHtg = (month(app.t(ind)) > 10 | month(app.t(ind)) < 5).*idealDtHtg;
        end
        handle =((app.mdlHtgClCoeff(1,3))./idealDtHtg) - 1;
        htgClIdeal = real((idealDtHtg > 0.1).*((log(handle) - app.mdlHtgClCoeff(1,2))/app.mdlHtgClCoeff(1,1)));
        htgClIdeal(htgClIdeal<0) = 0;
        htgClIdeal(htgClIdeal>1) = 1;
   
        scatter(app.uiax,app.tOa(ind),htgClIdeal,8,[0 0 1],'filled','o','MarkerFaceAlpha',.2,'MarkerEdgeAlpha',.2)
        hold (app.uiax,'on')
        if app.seasonalAvailability == 1
            handle = app.sHc(ind)/100.*(month(app.t(ind)) > 10 | month(app.t(ind)) < 5);
            mae.htg = mean(abs(htgClIdeal(month(app.t(ind)) > 10 | month(app.t(ind)) < 5) - handle(month(app.t(ind)) > 10 | month(app.t(ind)) < 5)));
        else
            handle = app.sHc(ind)/100;
            mae.htg = mean(abs(htgClIdeal - handle));
        end
        
    scatter(app.uiax,app.tOa(ind),handle,8,[1 0 0],'filled','o','MarkerFaceAlpha',.2,'MarkerEdgeAlpha',.2)
    
    legend(app.uiax,{'Expected','Measured'},'NumColumns',2,'Location','northoutside')
    legend(app.uiax,'boxoff') 
    
     % Fig 3
        app.fig3 = uifigure;
        app.fig3.Name = ['State of operation'];
        app.fig3.Position = [400 20 400 240]; % %[left bottom width height]in pixels
        set (app.fig3, 'Color', [1 1 1] )
 
      % Define plot axes and set their limits
        app.uiax=uiaxes(app.fig3);
        app.uiax.Position = [app.uiax.Position(1:2) [app.fig3.Position(3:4) - 2*app.uiax.Position(1:2)]];
        app.uiax.XLim = [-25 35];
        xticks(app.uiax,-25:5:35)
        xlabel(app.uiax,{['Outdoor temperature (' char(176) 'C)']},'fontsize',11)
        app.uiax.YLim = [0 1];
        yticks(app.uiax,0:0.2:1);
        ylabel(app.uiax,'Cooling coil','fontsize',11)
        set(app.uiax,'TickDir','out');
        app.uiax.Color = [1 1 1];
        app.uiax.BackgroundColor = [1 1 1];
        
        idealDtClg = min(app.tSa(ind) - (app.mdlDmp(oadIdeal).*app.tOa(ind) + (1 - app.mdlDmp(oadIdeal)).*app.tRa(ind))+app.pSa(ind)./840,-0.01);
        if app.seasonalAvailability == 1
            idealDtClg = (month(app.t(ind)) < 10 & month(app.t(ind)) > 5).*idealDtClg;
        end
        handle =((app.mdlClgClCoeff(1,3))./idealDtClg) - 1;
        clgClIdeal = real((idealDtClg < -0.1).*((log(handle) - app.mdlClgClCoeff(1,2))/app.mdlClgClCoeff(1,1)));
        clgClIdeal(clgClIdeal<0) = 0;
        clgClIdeal(clgClIdeal>1) = 1;
    
        scatter(app.uiax,app.tOa(ind),clgClIdeal,8,[0 0 1],'filled','o','MarkerFaceAlpha',.2,'MarkerEdgeAlpha',.2)
        hold (app.uiax,'on')
        
        if app.seasonalAvailability == 1
            handle = app.sCc(ind)/100.*(month(app.t(ind)) < 10 & month(app.t(ind)) > 5);
            mae.clg = mean(abs(clgClIdeal(month(app.t(ind)) < 10 & month(app.t(ind)) > 5) - handle(month(app.t(ind)) < 10 & month(app.t(ind)) > 5)));
        else
            handle = app.sCc(ind)/100;
            mae.clg = mean(abs(clgClIdeal - handle));
        end
        
        scatter(app.uiax,app.tOa(ind),handle,8,[1 0 0],'filled','o','MarkerFaceAlpha',.2,'MarkerEdgeAlpha',.2)
   
        legend(app.uiax,{'Expected','Measured'},'NumColumns',2,'Location','northoutside')
        legend(app.uiax,'boxoff')
        
        faults.SoO = (mae.dmp > 0.2 | mae.clg > 0.2 | mae.htg > 0.2);
        
        app.SoOFaults = double(faults.SoO);
        app.SoOEF.Value = app.SoOFaults;

        exportgraphics(app.fig1,'fig5a.png','Resolution',600)
        exportgraphics(app.fig2,'fig5b.png','Resolution',600)
        exportgraphics(app.fig3,'fig5c.png','Resolution',600)
        
        end

        % Button pushed function: TemperatureandairflowButton
        function TemperatureandairflowButtonPushed(app, event)
           
            WB = waitbar(0, 'ahuDoctor', 'Name', 'Detect temperature and airflow faults',...
            'CreateCancelBtn', 'setappdata(gcbf,     ''canceling'', 1)');
            setappdata(WB,'canceling',0);
            
            % zone temperature and airflow control faults, summer
            timeOfDay = hour(app.t);
            dayOfWeek = weekday(app.t);
            monthOfYear =  month(app.t);

            ind = find((timeOfDay > 9 & timeOfDay < 17) & (dayOfWeek > 1 & dayOfWeek < 7) & (monthOfYear > 10 | monthOfYear < 5));
            tInWntr = mean(app.tIn(ind,:));
            qFloWntr = app.qFlo(ind,:);
            qFloSpWntr = app.qFloSp(ind,:);
            qFloWntrErr = mean((qFloWntr - qFloSpWntr)./max(qFloSpWntr,1));
            
            waitbar(0.5,WB,'Detect temperature and airflow faults');

            ind = find((timeOfDay > 9 & timeOfDay < 17) & (dayOfWeek > 1 & dayOfWeek < 7) & (monthOfYear < 10 & monthOfYear > 5));
            tInSmr = mean(app.tIn(ind,:));
            qFloSmr = app.qFlo(ind,:);
            qFloSpSmr = app.qFloSp(ind,:);
            qFloSmrErr = mean((qFloSmr - qFloSpSmr)./max(qFloSpSmr,1));   

            ind = (tInWntr < 20 | tInWntr > 25) | (abs(qFloWntrErr) > 0.2) | (tInSmr < 20 | tInSmr > 25) | (abs(qFloSmrErr) > 0.2);
            faults.zone = {app.VAVfiles(ind)};
            app.fracFaultyZone = sum(ind)/length(app.qFlo(1,:));
            
            waitbar(0.9,WB,'Detect temperature and airflow faults');
            delete (WB)
            
       % generate a plot defining the behaviour
        delete (app.fig)
        delete (app.fig1)
        delete (app.fig2)
        delete (app.fig3)
        
        app.fig1 = uifigure;
        app.fig1.Name = ['Zone temperature and airflow control'];
        app.fig1.Position = [400 200 400 400]; % %[left bottom width height]in pixels
        set (app.fig1, 'Color', [1 1 1] )
 
       % Define plot axes and set their limits
        app.uiax=uiaxes(app.fig1);
        app.uiax.Position = [app.uiax.Position(1:2) [app.fig1.Position(3:4) - 2*app.uiax.Position(1:2)]];
        app.uiax.XLim = [15 30];
        xticks(app.uiax,15:3:30)
        app.uiax.YLim = [-100 100];
        yticks(app.uiax,-100:20:100);
        xlabel(app.uiax,'$t_{in}$ $(^{o}C)$','Interpreter','latex')
        app.uiax.XLabel.FontSize = 10;
        ylabel(app.uiax,'$\frac{q_{flo} - q_{flo,sp}}{q_{flo,sp}}$ $(\%)\qquad$','Interpreter','latex','fontsize',14)
        app.uiax.YLabel.FontSize = 10;
        set(app.uiax,'TickDir','out');  
        app.uiax.Title.String = 'Summer';
        app.uiax.Color = [1 1 1];
        app.uiax.BackgroundColor = [1 1 1];
        
        s= scatter(app.uiax,max(min(tInSmr,30),15),max(min(qFloSmrErr.*100,100),-100),36,'k','filled');
        s.MarkerEdgeAlpha = 0.4;
        s.MarkerFaceAlpha = 0.4;
        hold (app.uiax,'on')
        
        text(app.uiax,21.5,15,'normal','FontSize',10)
        text(app.uiax,16,2,'cold','FontSize',10)
        text(app.uiax,28,2,'hot','FontSize',10)
        text(app.uiax,21.5,80,'high flow','FontSize',10)
        text(app.uiax,21.5,-80,'low flow','FontSize',10)
        
        % really messed up
        xBox = [15 15 30 30];
        yBox = [-100 100 100 -100];
        s = patch(app.uiax,xBox, yBox, 'red', 'FaceColor', 'red', 'FaceAlpha', 0.1);        

        % messed up
        xBox = [18 18 27 27];
        yBox = [-50 50 50 -50];
        s = patch(app.uiax,xBox, yBox, 'yellow', 'FaceColor', 'yellow', 'FaceAlpha', 0.1);     

        % normal
        xBox = [20 20 25 25];
        yBox = [-20 20 20 -20];
        s = patch(app.uiax,xBox, yBox, 'green', 'FaceColor', 'green', 'FaceAlpha', 0.1); 
        
        % zone temperature and airflow control faults, winter
            timeOfDay = hour(app.t);
            dayOfWeek = weekday(app.t);
            monthOfYear =  month(app.t);

            ind = find((timeOfDay > 9 & timeOfDay < 17) & (dayOfWeek > 1 & dayOfWeek < 7) & (monthOfYear > 10 | monthOfYear < 5));
            tInWntr = mean(app.tIn(ind,:));
            qFloWntr = app.qFlo(ind,:);
            qFloSpWntr = app.qFloSp(ind,:);
            qFloWntrErr = mean((qFloWntr - qFloSpWntr)./max(qFloSpWntr,1));

            ind = find((timeOfDay > 9 & timeOfDay < 17) & (dayOfWeek > 1 & dayOfWeek < 7) & (monthOfYear < 10 & monthOfYear > 5));
            tInSmr = mean(app.tIn(ind,:));
            qFloSmr = app.qFlo(ind,:);
            qFloSpSmr = app.qFloSp(ind,:);
            qFloSmrErr = mean((qFloSmr - qFloSpSmr)./max(qFloSpSmr,1));   

            ind = (tInWntr < 20 | tInWntr > 25) | (abs(qFloWntrErr) > 0.2) | (tInSmr < 20 | tInSmr > 25) | (abs(qFloSmrErr) > 0.2);
            faults.zone = {app.VAVfiles(ind)};
            app.fracFaultyZone = sum(ind)/length(app.qFlo(1,:));
            
            app.TempFlowFaultyZones = faults.zone; % Excel file name of faulty zones
            app.TempFlowFaultyZonesNumber = app.fileNumber(ind);
            app.TempFlowEF.Value = round(app.fracFaultyZone,2);
            
        % generate a plot defining the behaviour
        
        app.fig2 = uifigure;
        app.fig2.Name = ['Zone temperature and airflow control'];
        app.fig2.Position = [800 200 400 400]; % %[left bottom width height]in pixels
        set (app.fig2, 'Color', [1 1 1] )
 
 % Define plot axes and set their limits
        app.uiax=uiaxes(app.fig2);
        app.uiax.Position = [app.uiax.Position(1:2) [app.fig2.Position(3:4) - 2*app.uiax.Position(1:2)]];
        app.uiax.XLim = [15 30];
        xticks(app.uiax,15:3:30)
        app.uiax.YLim = [-100 100];
        yticks(app.uiax,-100:20:100);
        xlabel(app.uiax,'$t_{in}$ $(^{o}C)$','Interpreter','latex')
        app.uiax.XLabel.FontSize = 10;
        ylabel(app.uiax,'$\frac{q_{flo} - q_{flo,sp}}{q_{flo,sp}}$ $(\%)\qquad$','Interpreter','latex','fontsize',14)
        app.uiax.YLabel.FontSize = 10;
        set(app.uiax,'TickDir','out');  
        app.uiax.Title.String = 'winter';
        app.uiax.Color = [1 1 1];
        app.uiax.BackgroundColor = [1 1 1];
        
    % graphically present the results for winter

    s= scatter(app.uiax,max(min(tInWntr,30),15),max(min(qFloWntrErr.*100,100),-100),36,'k','filled');
    s.MarkerEdgeAlpha = 0.4;
    s.MarkerFaceAlpha = 0.4;
    hold (app.uiax,'on')
    
    text(app.uiax,21.5,15,'normal','FontSize',10)
    text(app.uiax,16,2,'cold','FontSize',10)
    text(app.uiax,28,2,'hot','FontSize',10)
    text(app.uiax,21.5,80,'high flow','FontSize',10)
    text(app.uiax,21.5,-80,'low flow','FontSize',10)

    % really messed up
    xBox = [15 15 30 30];
    yBox = [-100 100 100 -100];
    s = patch(app.uiax,xBox, yBox, 'red', 'FaceColor', 'red', 'FaceAlpha', 0.1);        

    % messed up
    xBox = [18 18 27 27];
    yBox = [-50 50 50 -50];
    s = patch(app.uiax,xBox, yBox, 'yellow', 'FaceColor', 'yellow', 'FaceAlpha', 0.1);     

    % normal
    xBox = [20 20 25 25];
    yBox = [-20 20 20 -20];
    s = patch(app.uiax,xBox, yBox, 'green', 'FaceColor', 'green', 'FaceAlpha', 0.1); 

    exportgraphics(app.fig1,'fig3a.png','Resolution',600)
    exportgraphics(app.fig2,'fig3b.png','Resolution',600)
    
        end

        % Button pushed function: CoolingcoilButton
        function CoolingcoilButtonPushed(app, event)
           
            WB = waitbar(0, 'ahuDoctor', 'Name', 'Detect cooling coil faults',...
            'CreateCancelBtn', 'setappdata(gcbf,     ''canceling'', 1)');
            setappdata(WB,'canceling',0); 
            
    % cooling coil model
    % fan operating hours when heating is on and cooling is off
        if app.seasonalAvailability == 1
            ind = app.sFan > 0 & app.sHc > 0 & app.sCc == 0 & (month(app.t) > 10 | month(app.t) < 5) & app.sHc < 100;
        else
            ind = app.sFan > 0 & app.sHc > 0 & app.sCc == 0 & app.sHc < 100;
        end
        
    % mixed air estimate using the mixing box model
        tMa = (app.mdlDmp(app.sOa(ind)./100).*app.tOa(ind) + (1-app.mdlDmp(app.sOa(ind)./100)).*app.tRa(ind));
        yHtg = app.tSa(ind) - tMa - app.pSa(ind)./840;
        xHtg = app.sHc(ind)/100;

        waitbar(0.5,WB,'Detect cooling coil faults');
        
        ft = fittype('c/(1+exp(a*x+b))');
        options = fitoptions(ft);
        options.Robust = 'Bisquare';
        options.Lower = [-20  -20 -20];
        options.Upper = [20    20  20];
        [mdlHtgCl,gofHtgCl] = fit(xHtg,yHtg,ft,options);

    % cooling coil model
    % fan operating hours when heating is off and cooling is on
        if app.seasonalAvailability == 1
             ind = app.sFan > 0 & app.sHc == 0 & app.sCc > 0 & (month(app.t) < 10 & month(app.t) > 5) & app.sCc < 100;
        else 
            ind = app.sFan > 0 & app.sHc == 0 & app.sCc > 0 & app.sCc < 100;
        end
    % mixed air estimate using the mixing box model
    tMa = (app.mdlDmp(app.sOa(ind)./100).*app.tOa(ind) + (1-app.mdlDmp(app.sOa(ind)./100)).*app.tRa(ind));
    yClg = app.tSa(ind) - tMa + app.pSa(ind)./840;
    xClg = app.sCc(ind)/100;

    ft = fittype('c/(1+exp(a*x+b))');
    options = fitoptions(ft);
    options.Robust = 'Bisquare';
    options.Lower = [-20  -20 -20];
    options.Upper = [20    20  20];
    [mdlClgCl,gofClgCl] = fit(xClg,yClg,ft,options);

        if (mdlHtgCl(1) - mdlHtgCl(0)) > 5 & mdlHtgCl(0) < 5
            faults.sHc = 0;
        else
        faults.sHc = 1;
        end

        if (mdlClgCl(1) - mdlClgCl(0)) < -5 & mdlClgCl(0) > -5
            faults.sCc = 0;
        else
            faults.sCc = 1;
        end
    
        waitbar(0.5,WB,'Detect cooling coil faults');
        delete (WB)
        
    % generate a plot defining the behaviour
    
        delete (app.fig)
        delete (app.fig1)
        delete (app.fig2)
        delete (app.fig3)
        
        app.fig = uifigure;
        app.fig.Name = ['Heating and cooling coil models'];
        app.fig.Position = [400 200 400 400]; % %[left bottom width height]in pixels
        set (app.fig, 'Color', [1 1 1] )
 
     % Define plot axes and set their limits
        app.uiax=uiaxes(app.fig);
        app.uiax.Position = [app.uiax.Position(1:2) [app.fig.Position(3:4) - 2*app.uiax.Position(1:2)]];
        app.uiax.XLim = [0 1];
        xticks(app.uiax,0:0.2:1)
        %uiax.YLim = [0 1];
        %yticks(uiax,0:0.2:1)
        xlabel(app.uiax,'Coil valve fraction on')
        ylabel(app.uiax,{['Temperature change (' char(176) 'C)']})
        set(app.uiax,'TickDir','out');
        %uiax.FontName = 'Times New Roman';
        %uiax.FontSize = 12;
        app.uiax.Color = [1 1 1];
        app.uiax.BackgroundColor = [1 1 1];
        
        scatter(app.uiax,xHtg,yHtg,8,[1 0 0],'filled','o','MarkerFaceAlpha',.1,'MarkerEdgeAlpha',.1)
        hold(app.uiax,'on');
        ha = plot(app.uiax,(0:0.01:1)',mdlHtgCl(0:0.01:1),'r','LineWidth',2);
        hold(app.uiax,'on');
        scatter(app.uiax,xClg,yClg,8,[0 0 1],'filled','o','MarkerFaceAlpha',.1,'MarkerEdgeAlpha',.1)
        hold(app.uiax,'on');
        hb = plot(app.uiax,(0:0.01:1)',mdlClgCl(0:0.01:1),'b','LineWidth',2);
        legend(app.uiax,[ha hb], {'Heating coil','Cooling coil'},'NumColumns',2,'Location','northoutside')
        legend(app.uiax,'boxoff')
        
        app.sCcFault = faults.sCc;
        app.CCEF.Value = app.sCcFault;

        exportgraphics(app.uiax,'fig2.png','Resolution',600)
        
        end

        % Button pushed function: VAVboxButton
        function VAVboxButtonPushed(app, event)
        
            WB = waitbar(0, 'ahuDoctor', 'Name', 'Detect vav box faults',...
            'CreateCancelBtn', 'setappdata(gcbf,     ''canceling'', 1)');
            setappdata(WB,'canceling',0); 
            
        % VAV box fault
        % VAV terminal model
        for i = 1:length(app.sDmp(1,:))
            ind = app.sFan > 0 & app.pSa > 100 & app.qFlo(:,i) > 0;
            X = [(app.sDmp(ind,i)./100).*sqrt(app.pSa(ind)),sqrt(app.pSa(ind))];
            y = [app.qFlo(ind,i)];
            mdl = fitlm(X,y,'Intercept',false);
            mdlVAV.prmtr(:,i) = mdl.Coefficients.Estimate;
            mdlVAV.gof(:,i) = mdl.Rsquared.Ordinary;
    
            yEstLowPres = mdl.Coefficients.Estimate(1)*((linspace(0.2,1,100))'.*15) +...
                          mdl.Coefficients.Estimate(2)*15;
   
            yEstHighPres = mdl.Coefficients.Estimate(1)*((linspace(0.2,1,100))'.*20) +...
                           mdl.Coefficients.Estimate(2)*20;  
        end

            ind = mdlVAV.prmtr(1,:) <= 0;
            faults.vav = {app.VAVfiles(ind)};
            app.fracFaultyVav = sum(ind)/length(app.qFlo(1,:));
            
            waitbar(0.9,WB,'Detect vav box faults');
            delete (WB)
            
            app.VAVFaultyZones = faults.vav; % A list of faulty zones excel file name
            app.VAVFaultyZonesNumber = app.fileNumber(ind);
            app.VAVBoxEF.Value = round(app.fracFaultyVav,2);
            
        end

        % Button pushed function: ModeofoperationButton
        function ModeofoperationButtonPushed(app, event)
        
            WB = waitbar(0, 'ahuDoctor', 'Name', 'Detect mode of operation faults',...
            'CreateCancelBtn', 'setappdata(gcbf,     ''canceling'', 1)');
            setappdata(WB,'canceling',0); 
            
            % mode of operation
        timeOfDay = hour(app.t);
        dayOfWeek = weekday(app.t);

        if max(app.sFan) > 1
            app.sFan = app.sFan./100;
        end

        k = 1; numStateChange = []; timeOfSwitchOn = []; timeOfSwitchOff = [];
            for i = floor(min(app.t))+1:floor(max(app.t))-2
                numStateChange(k,1) = sum(abs(diff(app.sFan(app.t >= i & app.t <= i + 1))) > 0.5);
                timeOfSwitchOn = [timeOfSwitchOn;timeOfDay(diff(app.sFan(app.t >= i & app.t <= i + 1)) > 0.5)];
                timeOfSwitchOff = [timeOfSwitchOff;timeOfDay(diff(app.sFan(app.t >= i & app.t <= i + 1)) < -0.5)];
        k = k + 1;
            end

        if sum(numStateChange == 2)/length(numStateChange) < 0.5
            faults.MoO = 1;
        else
            faults.MoO = 0;
        end
        
         waitbar(0.9,WB,'Detect mode of operation faults');
         delete (WB)
         
        app.MoOFault = faults.MoO;
        app.MoOEF.Value = app.MoOFault;
              
       % generate plots defining the behaviour
        
        delete (app.fig)
        delete (app.fig1)
        delete (app.fig2)
        delete (app.fig3)
        
       % Fig 1
        app.fig1 = uifigure;
        app.fig1.Name = ['Mode of operation'];
        app.fig1.Position = [400 440 400 400]; % %[left bottom width height]in pixels
        set (app.fig1, 'Color', [1 1 1] )
 
       % Define plot axes and set their limits
        app.uiax=uiaxes(app.fig1);
        app.uiax.Position = [app.uiax.Position(1:2) [app.fig1.Position(3:4) - 2*app.uiax.Position(1:2)]];
        app.uiax.XLim = [-0.49 10];
        xticks(app.uiax,0:1:10)
        %uiax.YLim = [-100 100];
        %yticks(uiax,-100:20:100);
        xlabel(app.uiax,{'Daily fan state change instances'},'fontsize',11)
        ylabel(app.uiax,{'Fraction of days'},'fontsize',11)
        set(app.uiax,'TickDir','out');  
        app.uiax.Color = [1 1 1];
        app.uiax.BackgroundColor = [1 1 1];
        
        edges = [-0.5:10.5];
        h = histogram(app.uiax,numStateChange,edges,'Normalization','probability');
        h.FaceColor = [0 0 0];
        h.FaceAlpha = 0.1;
        h.EdgeColor = 'k';
        h.EdgeAlpha = 0.7;
        
       % Fig 2
        app.fig2 = uifigure;
        app.fig2.Name = ['Mode of operation'];
        app.fig2.Position = [400 20 400 400]; % %[left bottom width height]in pixels
        set (app.fig2, 'Color', [1 1 1] )
 
       % Define plot axes and set their limits
        app.uiax=uiaxes(app.fig2);
        app.uiax.Position = [app.uiax.Position(1:2) [app.fig2.Position(3:4) - 2*app.uiax.Position(1:2)]];
        %uiax.XLim = [-0.49 10];
        xticks(app.uiax,0:2:24)
        app.uiax.YLim = [0 1];
        %yticks(uiax,-100:20:100);
        xlabel(app.uiax,{'Time of day (h)'},'fontsize',11)
        ylabel(app.uiax,{'Fraction of fan state changes'},'fontsize',11)
        set(app.uiax,'TickDir','out');  
        app.uiax.Color = [1 1 1];
        app.uiax.BackgroundColor = [1 1 1];
        
        edges = [0:24];
        h = histogram(app.uiax,timeOfSwitchOn,edges,'Normalization','probability');
        h.FaceColor = [0 0 0];
        h.FaceAlpha = 0.1;
        h.EdgeColor = 'k';
        h.EdgeAlpha = 0.7;
        
        hold(app.uiax,'on');
        
        h = histogram(app.uiax,timeOfSwitchOff,edges,'Normalization','probability');
        h.FaceColor = [1 0 0];
        h.FaceAlpha = 0.1;
        h.EdgeColor = 'r';
        h.EdgeAlpha = 0.7;
        hold(app.uiax,'on');
        legend(app.uiax,'Fan switch on','Fan switch off')
        legend(app.uiax,'boxoff')  

        exportgraphics(app.fig1,'fig6a.png','Resolution',600)
        exportgraphics(app.fig2,'fig6b.png','Resolution',600)

        end

        % Button pushed function: SupplyairtemperaturesetpointButton
        function SupplyairtemperaturesetpointButtonPushed(app, event)
        
        WB = waitbar(0, 'ahuDoctor', 'Name', 'Detect supply air temperature reset faults',...
            'CreateCancelBtn', 'setappdata(gcbf,     ''canceling'', 1)');
            setappdata(WB,'canceling',0); 
            
        timeOfDay = hour(app.t);
        dayOfWeek = weekday(app.t);
            
        waitbar(0.9,WB,'Detect supply air temperature reset faults');
        delete (WB)
         
       % supply air temperature setpoint reset
        delete (app.fig)
        delete (app.fig1)
        delete (app.fig2)
        delete (app.fig3)
        
        app.fig = uifigure;
        app.fig.Name = ['SATReset'];
        app.fig.Position = [400 200 400 400]; % %[left bottom width height]in pixels
        set (app.fig, 'Color', [1 1 1] )
 
       % Define plot axes and set their limits
        app.uiax=uiaxes(app.fig);
        app.uiax.Position = [app.uiax.Position(1:2) [app.fig.Position(3:4) - 2*app.uiax.Position(1:2)]];
        app.uiax.XLim = [-25 30];
        xticks(app.uiax,-25:5:30)
        app.uiax.YLim = [10 24];
        yticks(app.uiax,10:2:24);
        xlabel(app.uiax,{['Outdoor air temperature (' char(176) 'C)']},'fontsize',11)
        ylabel(app.uiax,{['Supply air temperature (' char(176) 'C)']},'fontsize',11)
        set(app.uiax,'TickDir','out');  
        app.uiax.Color = [1 1 1];
        app.uiax.BackgroundColor = [1 1 1];

        ind = isoutlier(app.tSa) == 0 & (timeOfDay > 7 & timeOfDay < 18) & (dayOfWeek > 1 & dayOfWeek < 7);
        
        scatter(app.uiax,app.tOa(ind),app.tSa(ind),'filled','o','MarkerFaceAlpha',.1,'MarkerEdgeAlpha',.1)
        hold(app.uiax,'on');
    
        handle = -25:30;
        satResetPrmtr = [12,17,12,-12;13,20,19,-6];
        store = [];
        for i = 1:2
            tSaIdeal = (handle > satResetPrmtr(i,3)).*satResetPrmtr(i,1)...
                   +(handle < satResetPrmtr(i,4)).*satResetPrmtr(i,2);
            tSaIdeal(tSaIdeal == 0) = flip(interp1([satResetPrmtr(i,4);satResetPrmtr(i,3)],[satResetPrmtr(i,1);satResetPrmtr(i,2)],(satResetPrmtr(i,4):satResetPrmtr(i,3))'));
            tSaIdeal = interp1(handle,tSaIdeal,-25:30);
            store = [store,tSaIdeal'];
        end

        plot(app.uiax,handle',store(:,1),'r','LineWidth',2)
    
        hold(app.uiax,'on');
    
        plot(app.uiax,handle',store(:,2),'r--','LineWidth',2)
    
        hold(app.uiax,'on');
    
        s = patch(app.uiax,[handle';flip(handle')],[store(:,1);flip(store(:,2))],'r');
        s.FaceAlpha = 0.1;
        s.EdgeColor = 'w';
        s.EdgeAlpha = 0;
        legend(app.uiax,{'Measured','Expected low','Expected high'},'NumColumns',2,'Location','northoutside')
        legend(app.uiax,'boxoff')  

       % calculate the distance from expected low and high limits of expected sat
    handle = app.tOa(ind);
    satResetPrmtr = [12,17,12,-12;13,20,19,-6];
    store = [];
    store (:,1) = (handle < -12).*17 + (handle > 12).*12 + (handle <= 12 & handle >= -12).*((12 - handle)/24*5 + 12);
    store (:,2) = (handle < -6 ).*20 + (handle > 19).*13 + (handle <= 19 & handle >= -6).* ((19 - handle)/25*7 + 13);

    fracTimeOutsideRange = mean(app.tSa(ind) < store(:,1) | app.tSa(ind) > store(:,2));

    if fracTimeOutsideRange > 0.2
        faults.tSa = 1;
    else
        faults.tSa = 0;
    end
    
    app.tSaFault = faults.tSa;
    app.SATRestEF.Value = app.tSaFault;

    exportgraphics(app.fig,'fig7.png','Resolution',600)

        end

        % Button pushed function: DuctstaticpressuresetpointButton
        function DuctstaticpressuresetpointButtonPushed(app, event)
        
        timeOfDay = hour(app.t);
        dayOfWeek = weekday(app.t);
        ind = isoutlier(app.tSa) == 0 & (timeOfDay > 7 & timeOfDay < 18) & (dayOfWeek > 1 & dayOfWeek < 7);
            
        % duct static pressure reset fault
        delete (app.fig)
        delete (app.fig1)
        delete (app.fig2)
        delete (app.fig3)
        
        app.fig = uifigure;
        app.fig.Name = ['SAPReset'];
        app.fig.Position = [400 200 400 400]; % %[left bottom width height]in pixels
        set (app.fig, 'Color', [1 1 1] )
 
       % Define plot axes and set their limits
        app.uiax=uiaxes(app.fig);
        app.uiax.Position = [app.uiax.Position(1:2) [app.fig.Position(3:4) - 2*app.uiax.Position(1:2)]];
        app.uiax.XLim = [-0.49 10.49];
        xticks(app.uiax,0:10)
        app.uiax.YLim = [0 1];
        %yticks(uiax,10:1:24);
        xlabel(app.uiax,{['Number of dampers fully open']},'fontsize',11)
        ylabel(app.uiax,{['Fraction of time']},'fontsize',11)
        set(app.uiax,'TickDir','out');  
        app.uiax.Color = [1 1 1];
        app.uiax.BackgroundColor = [1 1 1];


        h = rectangle(app.uiax,'Position',[1.5 0 4 1],'FaceColor',[1 0 0 0.1],'EdgeColor',[1 0 0 0.7]);
        text(app.uiax,2.5,0.85,{'normal','range'})
        hold(app.uiax,'on');
        h = histogram(app.uiax,sum(app.sDmp(ind,:) > 90,2),'Normalization','probability');
        h.BinEdges = [-0.5:10.5];
        h.FaceColor = [0 0 0];
        h.FaceAlpha = 0.7;
        h.EdgeColor = 'k';
        h.EdgeAlpha = 0.7;

        if (sum((sum(app.sDmp(ind,:) > 90,2) < 2 | sum(app.sDmp(ind,:) > 90,2) > 5))/length(sum(app.sDmp(ind,:) > 90,2))) > 0.2
            faults.pSa = 1;
        else
            faults.pSa = 0;
        end
        
        app.pSaFault =  faults.pSa;
        app.SAPRestEF.Value = app.pSaFault;

        exportgraphics(app.fig,'fig8.png','Resolution',600)
        
        end

        % Button pushed function: SystemhealthindexButton
        function SystemhealthindexButtonPushed(app, event)
            
            %kpi = (1 - ((faults.sOa + faults.sHc + faults.sCc + length(faults.zone)/length(files) + length(faults.vav)/length(files) + faults.MoO + faults.SoO + faults.tSa + faults.pSa)/9))*100;
            
             app.kpi = (1 - ((app.sOaFaults + app.sHcFault + app.sCcFault + app.fracFaultyZone + app.fracFaultyVav + app.MoOFault + app.SoOFaults+ app.tSaFault + app.pSaFault)/9))*100;
            
             app.HealthIndexEF.Value = app.kpi; 
        end

        % Value changed function: HealthIndexEF
        function HealthIndexEFValueChanged(app, event)
            value = app.HealthIndexEF.Value;
            
        end

        % Value changed function: SeasonalavailabilityEditField
        function SeasonalavailabilityEditFieldValueChanged(app, event)
            value = app.SeasonalavailabilityEditField.Value;

            if value == 1
                    app.seasonalAvailability = 1;
                    
            else 
                    app.seasonalAvailability = 0;
            end 
            
        end

        % Button pushed function: GeneratereportButton
        function GeneratereportButtonPushed(app, event)
    
            WB = waitbar(0, 'ahuDoctor', 'Name', 'Generating PDF Results Report',...
            'CreateCancelBtn', 'setappdata(gcbf,     ''canceling'', 1)');
            setappdata(WB,'canceling',0); 
            
    % Create PDF report for the results
    makeDOMCompilable();
    import mlreportgen.report.*
    import mlreportgen.dom.*
    
    rpt = Report("Results", "pdf");
    open(rpt);

    % Add a heading to the report
    text1 = ['ahuDoctor report: AHU VAV system health'];
    p1 = Paragraph(text1,'BodyPara');
    p1.Underline = 'none';
    p1.Style = {Bold(true),OuterMargin("0pt", "0pt","0pt","10pt"),FontSize('12pt')};
    p1.HAlign = 'center';
    add(rpt, p1);
    
    text2 = [string(datetime('today'))];
    p2 = Paragraph(text2,'BodyPara');
    p2.Style = {Bold(false),FontSize('11pt')};
    p2.Underline = 'none';
    p2.HAlign = 'center';
    add(rpt, p2);
    
    hr1 = HorizontalRule();
    hr1.Border = 'dashed';
    hr1.BorderColor = 'black';
    hr1.Style = {OuterMargin("0pt", "0pt","0pt","20pt")};
    add(rpt,hr1);

    % Hard and soft faults detected in AHU VAV system
    text3 = ['Hard and soft faults detected in AHU VAV system'];
    p3 = Paragraph(text3,'BodyPara');
    p3.Style = {Bold(true),OuterMargin("0pt", "0pt","0pt","10pt"),...
        FontSize('11pt'),Underline('single')};
    p3.HAlign = 'center';
    add(rpt, p3);
    
   % Table style 
    
    tableStyle = ...
    { ...
    Width("100%"), ...
    Border("solid"), ...
    RowSep("solid"), ...
    ColSep("solid") ...
    };

    tableEntriesStyle = ...
    { ...
    HAlign("center"), ...
    VAlign("middle"), ...
    FontFamily('Times New Roman'), FontSize('12')
    };

    headerRowStyle = ...
    { ...
    InnerMargin("2pt","2pt","2pt","2pt"), ...
    BackgroundColor("gray"), ...
    Bold(true) ...
    };
    
% Table 1 showing hard and soft fault results
    F1 = {'Mixing box dampers behave outside AMCA curves'};
    F2 = {'Heating coil valve stuck'};
    F3 = {'Cooling coil valve stuck'}; 
    F4 = {'Zone temperature and airflow control fault'};
    F5 = {'VAV terminal fault'};
    F6 = {'Deviation from expected state of operation'};
    F7 = {'Deviation from expected mode of operation'};
    F8 = {'Deviation from expected supply air temperature reset behaviour'}; 
    F9 = {'Deviation from expected supply air pressure reset behaviour'};
 
Fault = [F1;F2;F3;F4;F5;F6;F7;F8;F9];
Inspected = [1;1;1;length(app.qFlo(1,:));length(app.qFlo(1,:));1;1;1;1];

% Faults detected
    F1D = app.sOaFaults; % mixing box damper fault
    F2D = app.sHcFault; % heating coil valve fault
    F3D = app.sCcFault; % cooling coil valve fault
    F4D = app.fracFaultyZone * length(app.qFlo(1,:)); % number of temp and flow faulty zones
    F5D = app.fracFaultyVav * length(app.qFlo(1,:)); % number of vav faulty zones
    F6D = app.SoOFaults; % state of operation fault
    F7D = app.MoOFault; % mode of operation fault
    F8D = app.tSaFault; % supply air temperature setpoint reset fault
    F9D = app.pSaFault; % supply air pressure setpoint reset fault
    FaultsDetected = [F1D;F2D;F3D;F4D;F5D;F6D;F7D;F8D;F9D];
    ResultsTable1 = table (Fault, Inspected, FaultsDetected);
    
    T1 = Table(ResultsTable1,'UnruledTable');
    T1.Style = tableStyle;
    T1.TableEntriesStyle = tableEntriesStyle;
    firstRow = T1.Children(1);
    firstRow.Style = headerRowStyle; 
    add(rpt,T1);
    
    % Show overall system health index
    text4 = ['AHU VAV system health index:   ' num2str(round(app.kpi,0)) '%'];
    p4 = Paragraph(text4,'BodyPara');
    p4.Underline = 'none';
    p4.Style = {Bold(false),OuterMargin("0pt", "0pt","10pt","10pt"),FontSize('11pt')};
    p4.HAlign = 'center';
    add(rpt, p4);
    
    % Table2 showing zone air temperature and airflow controls faulty zones
    text5 = ['Zone temperature and airflow control faulty zones'];
    p5 = Paragraph(text5,'BodyPara');
    p5.Style = {Bold(true),OuterMargin("0pt", "0pt","0pt","10pt"),...
        FontSize('11pt'),Underline('single')};
    p5.HAlign = 'center';
    add(rpt, p5);
   
    zoneNumber = app.TempFlowFaultyZonesNumber';
    zoneExcelFileName = [app.TempFlowFaultyZones{:}]';
    ResultsTable2 = table (zoneNumber, zoneExcelFileName);
    
    T2 = Table(ResultsTable2,'UnruledTable');
    T2.Style = tableStyle;
    T2.TableEntriesStyle = tableEntriesStyle;
    firstRow = T2.Children(1);
    firstRow.Style = headerRowStyle; 
    add(rpt,T2);
   
    % Table3 showing VAV damper faulty zones
    text6 = ['VAV terminal box faulty zones'];
    p6 = Paragraph(text6,'BodyPara');
    p6.Style = {Bold(true),OuterMargin("0pt", "0pt","10pt","10pt"),...
        FontSize('11pt'),Underline('single')};
    p6.HAlign = 'center';
    add(rpt, p6);
    
    zoneNumber = app.VAVFaultyZonesNumber';
    zoneExcelFileName = [app.VAVFaultyZones{:}]';
    ResultsTable3 = table (zoneNumber, zoneExcelFileName);
    
    T3 = Table(ResultsTable3,'UnruledTable');
    T3.Style = tableStyle;
    T3.TableEntriesStyle = tableEntriesStyle;
    firstRow = T3.Children(1);
    firstRow.Style = headerRowStyle; 
    add(rpt,T3);
    
    waitbar(0.5,WB,'Generating PDF Results Report');

    % Visualizations of faults
    text7 = ['Visualizations of detected AHU VAV faults'];
    p7 = Paragraph(text7,'BodyPara');
    p7.Style = {Bold(true),OuterMargin("0pt", "0pt","10pt","10pt"),...
        FontSize('11pt'),Underline('single')};
    p7.HAlign = 'center';
    add(rpt, p7);
    
    % Visualizations of faults
    text8 = ['(1) Mixing box damper faults'];
    p8 = Paragraph(text8,'BodyPara');
    p8.Style = {Bold(true),OuterMargin("0pt", "0pt","10pt","20pt"),...
        FontSize('11pt'),Underline('single')};
    p8.HAlign = 'center';
    add(rpt, p8);

    img1 = Image("fig1.png");
    img1.Style = {Height('3in'),Width('3in'),HAlign('center')};
    add(rpt, img1);
    
    br = PageBreak();
    add(rpt, br);

    text9 = ['(2) Heating and cooling coil faults'];
    p9 = Paragraph(text9,'BodyPara');
    p9.Style = {Bold(true),OuterMargin("0pt", "0pt","10pt","20pt"),...
        FontSize('11pt'),Underline('single')};
    p9.HAlign = 'center';
    add(rpt, p9);

    img2 = Image("fig2.png");
    img2.Style = {Height('3in'),Width('3in'),HAlign('center')};
    add(rpt, img2);

    text10 = ['(3) Temperature and airflow control faults'];
    p10 = Paragraph(text10,'BodyPara');
    p10.Style = {Bold(true),OuterMargin("0pt", "0pt","10pt","20pt"),...
        FontSize('11pt'),Underline('single')};
    p10.HAlign = 'center';
    add(rpt, p10);

    img3a = Image("fig3a.png");
    img3a.Style = {Height('3in'),Width('3in'),HAlign('center')};

    img3b = Image("fig3b.png");
    img3b.Style = {Height('3in'),Width('3in'),HAlign('center')};

    lot = Table({img3a, ' ', img3b});
    lot.entry(1,1).Style = {Width('3.2in'), Height('3in')};
    lot.entry(1,2).Style = {Width('.2in'), Height('3in')};
    lot.entry(1,3).Style = {Width('3.2in'), Height('3in')};
    lot.Style = {ResizeToFitContents(false), Width('100%')};
    add(rpt, lot);
    
    br = PageBreak();
    add(rpt, br);
    
    text11 = ['(4) VAV termimal box faults'];
    p11 = Paragraph(text11,'BodyPara');
    p11.Style = {Bold(true),OuterMargin("0pt", "0pt","10pt","20pt"),...
        FontSize('11pt'),Underline('single')};
    p11.HAlign = 'center';
    add(rpt, p11);

    % VAV terminal model
        for i = 1:length(app.sDmp(1,:))
            ind = app.sFan > 0 & app.pSa > 100 & app.qFlo(:,i) > 0;
            X = [(app.sDmp(ind,i)./100).*sqrt(app.pSa(ind)),sqrt(app.pSa(ind))];
            y = [app.qFlo(ind,i)];
            mdl = fitlm(X,y,'Intercept',false);
            mdlVAV.prmtr(:,i) = mdl.Coefficients.Estimate;
            mdlVAV.gof(:,i) = mdl.Rsquared.Ordinary;
    
            yEstLowPres = mdl.Coefficients.Estimate(1)*((linspace(0.2,1,100))'.*15) +...
                          mdl.Coefficients.Estimate(2)*15;
   
            yEstHighPres = mdl.Coefficients.Estimate(1)*((linspace(0.2,1,100))'.*20) +...
                           mdl.Coefficients.Estimate(2)*20;  
        end

            ind = mdlVAV.prmtr(1,:) <= 0;
            faults.vav = {app.VAVfiles(ind)};
            app.fracFaultyVav = sum(ind)/length(app.qFlo(1,:));
            
            app.VAVFaultyZones = faults.vav; % Excel file name of faulty zones
            app.VAVFaultyZonesNumber = app.fileNumber(ind); % Sequential number of faulty zones
            app.VAVBoxEF.Value = round(app.fracFaultyVav,2);

            
        for i = 1:length(app.VAVFaultyZonesNumber(1,:))
            ind = app.sFan > 0 & app.pSa > 100 & app.qFlo(:,app.VAVFaultyZonesNumber(1,i)) > 0;

            X = [(app.sDmp(ind,app.VAVFaultyZonesNumber(1,i))./100).*sqrt(app.pSa(ind)),sqrt(app.pSa(ind))];
            y = [app.qFlo(ind,app.VAVFaultyZonesNumber(1,i))];

            mdl = fitlm(X,y,'Intercept',false);
            mdlVAV.prmtr(:,i) = mdl.Coefficients.Estimate;
            mdlVAV.gof(:,i) = mdl.Rsquared.Ordinary;
    
            yEstLowPres = mdl.Coefficients.Estimate(1)*((linspace(0.2,1,100))'.*15) +...
                          mdl.Coefficients.Estimate(2)*15;
   
            yEstHighPres = mdl.Coefficients.Estimate(1)*((linspace(0.2,1,100))'.*20) +...
                           mdl.Coefficients.Estimate(2)*20;

            fig = figure('visible','off');
            %'units','inch','position',[0,0,2,2]
            fig.Name = ['Zone VAV box',app.VAVFaultyZonesNumber(1,i)];
            %fig.Position = [0 0 100 100]; % %[left bottom width height]in pixels
            set (fig, 'Color', [1 1 1] )
            
            scatter((app.sDmp(ind,app.VAVFaultyZonesNumber(1,i))./100),app.qFlo(ind,app.VAVFaultyZonesNumber(1,i)),6,[0 0 0],'filled','o','MarkerFaceAlpha',.1,'MarkerEdgeAlpha',.1)
            hold on

            ha = plot((linspace(0.2,1,100))',max(yEstLowPres,0),'r','LineWidth',2);
            hb = plot((linspace(0.2,1,100))',max(yEstHighPres,0),'b--','LineWidth',2);
            
            legend([ha hb], {'200 Pa','400 Pa'},'NumColumns',2,'Location','northoutside')
            legend('boxoff')

            ylabel('VAV airflow (L/s)')
            xlabel('Damper fraction open')
            xlim([0 1])
            xticks(0:0.2:1)
            set(gca,'TickDir','out');
            box off  

            exportgraphics(fig,sprintf('fig4%d.png',i),'Resolution',600)

            img4 = Image(sprintf('fig4%d.png',i));
            img4.Style = {Height('3in'),Width('3in'),HAlign('center')};

            add(rpt, img4);
           

            [pathstr,name,ext] = fileparts([app.VAVFaultyZones{:}]);
            text = [char(name(1,i))];
            p = Paragraph(text,'BodyPara');
            p.Style = {Bold(true),OuterMargin("0pt", "0pt","10pt","20pt"),...
                FontSize('11pt'),Underline('none')};
            p.HAlign = 'center';
            add(rpt, p);
           
        end 

    text12 = ['(5) State of operation faults'];
    p12 = Paragraph(text12,'BodyPara');
    p12.Style = {Bold(true),OuterMargin("0pt", "0pt","10pt","20pt"),...
        FontSize('11pt'),Underline('single')};
    p12.HAlign = 'center';
    add(rpt, p12);

    img5a = Image("fig5a.png");
    img5a.Style = {Height('3in'),Width('4in'),HAlign('center')};
    add(rpt, img5a);

    text13 = [''];
    p13 = Paragraph(text13,'BodyPara');
    p13.Style = {Bold(true),OuterMargin("0pt", "0pt","10pt","10pt"),...
        FontSize('11pt'),Underline('single')};
    p13.HAlign = 'center';
    add(rpt, p13);

    img5b = Image("fig5b.png");
    img5b.Style = {Height('3in'),Width('4in'),HAlign('center')};
    add(rpt, img5b);

    text14 = [''];
    p14 = Paragraph(text14,'BodyPara');
    p14.Style = {Bold(true),OuterMargin("0pt", "0pt","10pt","10pt"),...
        FontSize('11pt'),Underline('single')};
    p14.HAlign = 'center';
    add(rpt, p14);

    img5c = Image("fig5c.png");
    img5c.Style = {Height('3in'),Width('4in'),HAlign('center')};
    add(rpt, img5c);

    br = PageBreak();
    add(rpt, br);

    text15 = ['(6) Mode of operation faults'];
    p15 = Paragraph(text15,'BodyPara');
    p15.Style = {Bold(true),OuterMargin("0pt", "0pt","10pt","20pt"),...
        FontSize('11pt'),Underline('single')};
    p15.HAlign = 'center';
    add(rpt, p15);

    img6a = Image("fig6a.png");
    img6a.Style = {Height('3in'),Width('4in'),HAlign('center')};
    add(rpt, img6a);

    text16 = [''];
    p16 = Paragraph(text16,'BodyPara');
    p16.Style = {Bold(true),OuterMargin("0pt", "0pt","10pt","10pt"),...
        FontSize('11pt'),Underline('single')};
    p16.HAlign = 'center';
    add(rpt, p16);

    img6b = Image("fig6b.png");
    img6b.Style = {Height('3in'),Width('4in'),HAlign('center')};
    add(rpt, img6b);

    br = PageBreak();
    add(rpt, br);

    waitbar(0.8,WB,'Generating PDF Results Report');
    

    text17 = ['(7) Supply air temperature setpoint reset fault'];
    p17 = Paragraph(text17,'BodyPara');
    p17.Style = {Bold(true),OuterMargin("0pt", "0pt","10pt","20pt"),...
        FontSize('11pt'),Underline('single')};
    p17.HAlign = 'center';
    add(rpt, p17);

    img7 = Image("fig7.png");
    img7.Style = {Height('3in'),Width('3in'),HAlign('center')};
    add(rpt, img7);

    text18 = ['(8) Duct static pressure reset fault'];
    p18 = Paragraph(text18,'BodyPara');
    p18.Style = {Bold(true),OuterMargin("0pt", "0pt","10pt","20pt"),...
        FontSize('11pt'),Underline('single')};
    p18.HAlign = 'center';
    add(rpt, p18);

    img8 = Image("fig8.png");
    img8.Style = {Height('3in'),Width('3in'),HAlign('center')};
    add(rpt, img8);
%}
    waitbar(0.9,WB,'Generating PDF Results Report');
    delete (WB)

    close(rpt);
    rptview(rpt)
    
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create AHU_fault_detector and hide until all components are created
            app.AHU_fault_detector = uifigure('Visible', 'off');
            app.AHU_fault_detector.Position = [100 100 312 815];
            app.AHU_fault_detector.Name = 'UI Figure';

            % Create ahuDoctorPanel
            app.ahuDoctorPanel = uipanel(app.AHU_fault_detector);
            app.ahuDoctorPanel.ForegroundColor = [0.0902 0 0];
            app.ahuDoctorPanel.TitlePosition = 'centertop';
            app.ahuDoctorPanel.Title = 'ahuDoctor';
            app.ahuDoctorPanel.BackgroundColor = [0.9412 0.9725 1];
            app.ahuDoctorPanel.FontWeight = 'bold';
            app.ahuDoctorPanel.FontSize = 16;
            app.ahuDoctorPanel.Position = [1 3 301 813];

            % Create LoaddataPanel
            app.LoaddataPanel = uipanel(app.ahuDoctorPanel);
            app.LoaddataPanel.TitlePosition = 'centertop';
            app.LoaddataPanel.Title = 'Load data';
            app.LoaddataPanel.BackgroundColor = [0.9608 1 0.9804];
            app.LoaddataPanel.FontWeight = 'bold';
            app.LoaddataPanel.Position = [0 713 300 75];

            % Create AHUButton
            app.AHUButton = uibutton(app.LoaddataPanel, 'push');
            app.AHUButton.ButtonPushedFcn = createCallbackFcn(app, @AHUButtonPushed, true);
            app.AHUButton.BackgroundColor = [0.9412 1 0.9412];
            app.AHUButton.Position = [9 15 76 30];
            app.AHUButton.Text = 'AHU';

            % Create VAVzonesButton
            app.VAVzonesButton = uibutton(app.LoaddataPanel, 'push');
            app.VAVzonesButton.ButtonPushedFcn = createCallbackFcn(app, @VAVzonesButtonPushed, true);
            app.VAVzonesButton.BackgroundColor = [0.9412 1 0.9412];
            app.VAVzonesButton.Position = [103 15 76 30];
            app.VAVzonesButton.Text = 'VAV zones';

            % Create ReaddataButton
            app.ReaddataButton = uibutton(app.LoaddataPanel, 'push');
            app.ReaddataButton.ButtonPushedFcn = createCallbackFcn(app, @ReaddataButtonPushed, true);
            app.ReaddataButton.BackgroundColor = [0.9412 1 0.9412];
            app.ReaddataButton.Position = [199 15 76 30];
            app.ReaddataButton.Text = 'Read data';

            % Create DetecthardfaultsPanel
            app.DetecthardfaultsPanel = uipanel(app.ahuDoctorPanel);
            app.DetecthardfaultsPanel.TitlePosition = 'centertop';
            app.DetecthardfaultsPanel.Title = 'Detect hard faults';
            app.DetecthardfaultsPanel.BackgroundColor = [0.9412 1 0.9412];
            app.DetecthardfaultsPanel.FontWeight = 'bold';
            app.DetecthardfaultsPanel.Position = [2 270 199 319];

            % Create SystemlevelPanel
            app.SystemlevelPanel = uipanel(app.DetecthardfaultsPanel);
            app.SystemlevelPanel.TitlePosition = 'centertop';
            app.SystemlevelPanel.Title = 'System-level ';
            app.SystemlevelPanel.BackgroundColor = [0.9608 1 0.9804];
            app.SystemlevelPanel.Position = [-2 162 200 138];

            % Create MixingboxButton
            app.MixingboxButton = uibutton(app.SystemlevelPanel, 'push');
            app.MixingboxButton.ButtonPushedFcn = createCallbackFcn(app, @MixingboxButtonPushed, true);
            app.MixingboxButton.BackgroundColor = [0.9412 1 0.9412];
            app.MixingboxButton.Position = [25 81 149 30];
            app.MixingboxButton.Text = 'Mixing box';

            % Create HeatingcoilButton
            app.HeatingcoilButton = uibutton(app.SystemlevelPanel, 'push');
            app.HeatingcoilButton.ButtonPushedFcn = createCallbackFcn(app, @HeatingcoilButtonPushed, true);
            app.HeatingcoilButton.BackgroundColor = [0.9412 1 0.9412];
            app.HeatingcoilButton.Position = [24 43 150 30];
            app.HeatingcoilButton.Text = 'Heating coil ';

            % Create CoolingcoilButton
            app.CoolingcoilButton = uibutton(app.SystemlevelPanel, 'push');
            app.CoolingcoilButton.ButtonPushedFcn = createCallbackFcn(app, @CoolingcoilButtonPushed, true);
            app.CoolingcoilButton.BackgroundColor = [0.9412 1 0.9412];
            app.CoolingcoilButton.Position = [25 6 150 30];
            app.CoolingcoilButton.Text = 'Cooling coil';

            % Create ZonelevelPanel
            app.ZonelevelPanel = uipanel(app.DetecthardfaultsPanel);
            app.ZonelevelPanel.TitlePosition = 'centertop';
            app.ZonelevelPanel.Title = 'Zone-level';
            app.ZonelevelPanel.BackgroundColor = [0.9608 1 0.9804];
            app.ZonelevelPanel.Position = [-2 -2 200 163];

            % Create TemperatureandairflowButton
            app.TemperatureandairflowButton = uibutton(app.ZonelevelPanel, 'push');
            app.TemperatureandairflowButton.ButtonPushedFcn = createCallbackFcn(app, @TemperatureandairflowButtonPushed, true);
            app.TemperatureandairflowButton.BackgroundColor = [0.9412 1 0.9412];
            app.TemperatureandairflowButton.Position = [25 107 150 30];
            app.TemperatureandairflowButton.Text = 'Temperature and airflow';

            % Create VAVboxButton
            app.VAVboxButton = uibutton(app.ZonelevelPanel, 'push');
            app.VAVboxButton.ButtonPushedFcn = createCallbackFcn(app, @VAVboxButtonPushed, true);
            app.VAVboxButton.BackgroundColor = [0.9412 1 0.9412];
            app.VAVboxButton.Position = [25 68 150 30];
            app.VAVboxButton.Text = 'VAV box ';

            % Create ZonenumberEditFieldLabel
            app.ZonenumberEditFieldLabel = uilabel(app.ZonelevelPanel);
            app.ZonenumberEditFieldLabel.HorizontalAlignment = 'right';
            app.ZonenumberEditFieldLabel.Position = [8 37 80 22];
            app.ZonenumberEditFieldLabel.Text = 'Zone number ';

            % Create ZonenumberEditField
            app.ZonenumberEditField = uieditfield(app.ZonelevelPanel, 'numeric');
            app.ZonenumberEditField.Position = [88 37 21 22];
            app.ZonenumberEditField.Value = 1;

            % Create CheckButton
            app.CheckButton = uibutton(app.ZonelevelPanel, 'push');
            app.CheckButton.ButtonPushedFcn = createCallbackFcn(app, @CheckButtonPushed, true);
            app.CheckButton.BackgroundColor = [0.9412 1 0.9412];
            app.CheckButton.Position = [119 37 65 21];
            app.CheckButton.Text = 'Check';

            % Create SelectzonenumberfromEditFieldLabel
            app.SelectzonenumberfromEditFieldLabel = uilabel(app.ZonelevelPanel);
            app.SelectzonenumberfromEditFieldLabel.HorizontalAlignment = 'right';
            app.SelectzonenumberfromEditFieldLabel.FontSize = 9;
            app.SelectzonenumberfromEditFieldLabel.FontAngle = 'italic';
            app.SelectzonenumberfromEditFieldLabel.Position = [9 8 108 22];
            app.SelectzonenumberfromEditFieldLabel.Text = 'Select zone number from ';

            % Create SelectzonenumberfromEditField
            app.SelectzonenumberfromEditField = uieditfield(app.ZonelevelPanel, 'numeric');
            app.SelectzonenumberfromEditField.HorizontalAlignment = 'center';
            app.SelectzonenumberfromEditField.FontSize = 9;
            app.SelectzonenumberfromEditField.FontAngle = 'italic';
            app.SelectzonenumberfromEditField.Position = [119 8 20 22];
            app.SelectzonenumberfromEditField.Value = 1;

            % Create toEditFieldLabel
            app.toEditFieldLabel = uilabel(app.ZonelevelPanel);
            app.toEditFieldLabel.HorizontalAlignment = 'right';
            app.toEditFieldLabel.FontSize = 9;
            app.toEditFieldLabel.FontAngle = 'italic';
            app.toEditFieldLabel.Position = [132 8 21 22];
            app.toEditFieldLabel.Text = 'to';

            % Create toEditField
            app.toEditField = uieditfield(app.ZonelevelPanel, 'numeric');
            app.toEditField.HorizontalAlignment = 'center';
            app.toEditField.FontSize = 9;
            app.toEditField.FontAngle = 'italic';
            app.toEditField.Position = [159 8 20 22];
            app.toEditField.Value = 1;

            % Create UserinputsPanel
            app.UserinputsPanel = uipanel(app.ahuDoctorPanel);
            app.UserinputsPanel.TitlePosition = 'centertop';
            app.UserinputsPanel.Title = 'User inputs';
            app.UserinputsPanel.BackgroundColor = [0.9608 1 0.9804];
            app.UserinputsPanel.FontWeight = 'bold';
            app.UserinputsPanel.Position = [0 588 300 126];

            % Create TextArea_2
            app.TextArea_2 = uitextarea(app.UserinputsPanel);
            app.TextArea_2.Editable = 'off';
            app.TextArea_2.HorizontalAlignment = 'center';
            app.TextArea_2.FontSize = 9;
            app.TextArea_2.FontAngle = 'italic';
            app.TextArea_2.BackgroundColor = [0.9608 0.9608 0.9608];
            app.TextArea_2.Position = [9 6 215 27];
            app.TextArea_2.Value = {' 1: Heating in winter and cooling in summer'; '0: Heating and cooling available yearround'};

            % Create SeasonalavailabilityEditFieldLabel
            app.SeasonalavailabilityEditFieldLabel = uilabel(app.UserinputsPanel);
            app.SeasonalavailabilityEditFieldLabel.BackgroundColor = [0.9608 1 0.9804];
            app.SeasonalavailabilityEditFieldLabel.HorizontalAlignment = 'center';
            app.SeasonalavailabilityEditFieldLabel.Position = [9 33 214 22];
            app.SeasonalavailabilityEditFieldLabel.Text = 'Seasonal availability ';

            % Create SeasonalavailabilityEditField
            app.SeasonalavailabilityEditField = uieditfield(app.UserinputsPanel, 'numeric');
            app.SeasonalavailabilityEditField.ValueChangedFcn = createCallbackFcn(app, @SeasonalavailabilityEditFieldValueChanged, true);
            app.SeasonalavailabilityEditField.HorizontalAlignment = 'center';
            app.SeasonalavailabilityEditField.BackgroundColor = [0.9608 0.9608 0.9608];
            app.SeasonalavailabilityEditField.Position = [234 33 50 22];

            % Create Minimummixingboxdamperpositionsetpointeg02EditFieldLabel
            app.Minimummixingboxdamperpositionsetpointeg02EditFieldLabel = uilabel(app.UserinputsPanel);
            app.Minimummixingboxdamperpositionsetpointeg02EditFieldLabel.BackgroundColor = [0.9608 1 0.9804];
            app.Minimummixingboxdamperpositionsetpointeg02EditFieldLabel.HorizontalAlignment = 'center';
            app.Minimummixingboxdamperpositionsetpointeg02EditFieldLabel.WordWrap = 'on';
            app.Minimummixingboxdamperpositionsetpointeg02EditFieldLabel.Position = [6 64 217 34];
            app.Minimummixingboxdamperpositionsetpointeg02EditFieldLabel.Text = 'Minimum mixing box damper position setpoint (e.g., 0.2)';

            % Create Minimummixingboxdamperpositionsetpointeg02EditField
            app.Minimummixingboxdamperpositionsetpointeg02EditField = uieditfield(app.UserinputsPanel, 'numeric');
            app.Minimummixingboxdamperpositionsetpointeg02EditField.HorizontalAlignment = 'center';
            app.Minimummixingboxdamperpositionsetpointeg02EditField.BackgroundColor = [0.9608 0.9608 0.9608];
            app.Minimummixingboxdamperpositionsetpointeg02EditField.Position = [234 64 50 34];

            % Create DetectsoftfaultsPanel
            app.DetectsoftfaultsPanel = uipanel(app.ahuDoctorPanel);
            app.DetectsoftfaultsPanel.TitlePosition = 'centertop';
            app.DetectsoftfaultsPanel.Title = 'Detect soft faults';
            app.DetectsoftfaultsPanel.BackgroundColor = [0.9412 1 0.9412];
            app.DetectsoftfaultsPanel.FontWeight = 'bold';
            app.DetectsoftfaultsPanel.Position = [0 73 201 195];

            % Create Panel
            app.Panel = uipanel(app.DetectsoftfaultsPanel);
            app.Panel.TitlePosition = 'centertop';
            app.Panel.BackgroundColor = [0.9608 1 0.9804];
            app.Panel.FontWeight = 'bold';
            app.Panel.Position = [0 0 201 173];

            % Create StateofoperationButton
            app.StateofoperationButton = uibutton(app.Panel, 'push');
            app.StateofoperationButton.ButtonPushedFcn = createCallbackFcn(app, @StateofoperationButtonPushed, true);
            app.StateofoperationButton.BackgroundColor = [0.9412 1 0.9412];
            app.StateofoperationButton.Position = [43 132 111 30];
            app.StateofoperationButton.Text = 'State of operation';

            % Create ModeofoperationButton
            app.ModeofoperationButton = uibutton(app.Panel, 'push');
            app.ModeofoperationButton.ButtonPushedFcn = createCallbackFcn(app, @ModeofoperationButtonPushed, true);
            app.ModeofoperationButton.BackgroundColor = [0.9412 1 0.9412];
            app.ModeofoperationButton.Position = [42 90 112 30];
            app.ModeofoperationButton.Text = 'Mode of operation';

            % Create SupplyairtemperaturesetpointButton
            app.SupplyairtemperaturesetpointButton = uibutton(app.Panel, 'push');
            app.SupplyairtemperaturesetpointButton.ButtonPushedFcn = createCallbackFcn(app, @SupplyairtemperaturesetpointButtonPushed, true);
            app.SupplyairtemperaturesetpointButton.BackgroundColor = [0.9412 1 0.9412];
            app.SupplyairtemperaturesetpointButton.Position = [7 47 186 30];
            app.SupplyairtemperaturesetpointButton.Text = 'Supply air temperature setpoint';

            % Create DuctstaticpressuresetpointButton
            app.DuctstaticpressuresetpointButton = uibutton(app.Panel, 'push');
            app.DuctstaticpressuresetpointButton.ButtonPushedFcn = createCallbackFcn(app, @DuctstaticpressuresetpointButtonPushed, true);
            app.DuctstaticpressuresetpointButton.BackgroundColor = [0.9412 1 0.9412];
            app.DuctstaticpressuresetpointButton.Position = [7 9 186 30];
            app.DuctstaticpressuresetpointButton.Text = 'Duct static pressure setpoint';

            % Create FaultsPanel
            app.FaultsPanel = uipanel(app.ahuDoctorPanel);
            app.FaultsPanel.TitlePosition = 'centertop';
            app.FaultsPanel.Title = 'Faults';
            app.FaultsPanel.BackgroundColor = [0.9608 1 0.9804];
            app.FaultsPanel.FontWeight = 'bold';
            app.FaultsPanel.FontSize = 11;
            app.FaultsPanel.Position = [200 73 100 515];

            % Create MBEF
            app.MBEF = uieditfield(app.FaultsPanel, 'numeric');
            app.MBEF.Position = [25 443 51 22];

            % Create HCEF
            app.HCEF = uieditfield(app.FaultsPanel, 'numeric');
            app.HCEF.Position = [24 402 51 22];

            % Create TempFlowEF
            app.TempFlowEF = uieditfield(app.FaultsPanel, 'numeric');
            app.TempFlowEF.Position = [24 305 51 22];

            % Create VAVBoxEF
            app.VAVBoxEF = uieditfield(app.FaultsPanel, 'numeric');
            app.VAVBoxEF.Position = [24 266 51 22];

            % Create SoOEF
            app.SoOEF = uieditfield(app.FaultsPanel, 'numeric');
            app.SoOEF.Position = [24 136 51 22];

            % Create MoOEF
            app.MoOEF = uieditfield(app.FaultsPanel, 'numeric');
            app.MoOEF.Position = [24 94 51 22];

            % Create CCEF
            app.CCEF = uieditfield(app.FaultsPanel, 'numeric');
            app.CCEF.Position = [24 368 51 22];

            % Create SATRestEF
            app.SATRestEF = uieditfield(app.FaultsPanel, 'numeric');
            app.SATRestEF.Position = [24 51 51 22];

            % Create SAPRestEF
            app.SAPRestEF = uieditfield(app.FaultsPanel, 'numeric');
            app.SAPRestEF.Position = [24 13 51 22];

            % Create Panel_2
            app.Panel_2 = uipanel(app.ahuDoctorPanel);
            app.Panel_2.TitlePosition = 'centertop';
            app.Panel_2.BackgroundColor = [0.9608 1 0.9804];
            app.Panel_2.FontWeight = 'bold';
            app.Panel_2.Position = [0 -2 300 75];

            % Create SystemhealthindexButton
            app.SystemhealthindexButton = uibutton(app.Panel_2, 'push');
            app.SystemhealthindexButton.ButtonPushedFcn = createCallbackFcn(app, @SystemhealthindexButtonPushed, true);
            app.SystemhealthindexButton.BackgroundColor = [0.9412 1 0.9412];
            app.SystemhealthindexButton.FontWeight = 'bold';
            app.SystemhealthindexButton.Position = [6 40 186 30];
            app.SystemhealthindexButton.Text = 'System health index (%)';

            % Create HealthIndexEF
            app.HealthIndexEF = uieditfield(app.Panel_2, 'numeric');
            app.HealthIndexEF.ValueChangedFcn = createCallbackFcn(app, @HealthIndexEFValueChanged, true);
            app.HealthIndexEF.FontWeight = 'bold';
            app.HealthIndexEF.Position = [222 44 51 22];

            % Create GeneratereportButton
            app.GeneratereportButton = uibutton(app.Panel_2, 'push');
            app.GeneratereportButton.ButtonPushedFcn = createCallbackFcn(app, @GeneratereportButtonPushed, true);
            app.GeneratereportButton.BackgroundColor = [0.9412 1 0.9412];
            app.GeneratereportButton.FontWeight = 'bold';
            app.GeneratereportButton.Position = [61 7 186 26];
            app.GeneratereportButton.Text = 'Generate report';

            % Show the figure after all components are created
            app.AHU_fault_detector.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = ahuDoctor_exported

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.AHU_fault_detector)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.AHU_fault_detector)
        end
    end
end