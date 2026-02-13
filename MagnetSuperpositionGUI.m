function MagnetDashboardGUI()
    % --- 1. Load Data ---
    if ~exist('MagnetMasterData.mat', 'file')
        error('MagnetMasterData.mat not found. Run the pre-processor script first.');
    end
    data = load('MagnetMasterData.mat');
    UnitFields = data.UnitFields;
    MasterGrid = data.MasterGrid;
    
    rawNames = fieldnames(UnitFields);
    % Sorting: Ensure Coil_11, Coil10, and Coil12 appear first as per notes
    priority = {'Coil_11', 'Coil10_5T', 'Coil12_1Tmain'};
    others = setdiff(rawNames, priority, 'stable');
    coilNames = [priority'; others];
    numCoils = length(coilNames);

    % --- 2. Create Figure & Dashboard Layout ---
    fig = uifigure('Name', 'Magnet Dashboard | Liverpool PDRA Final', 'Position', [50 50 1400 850]);
    mainLayout = uigridlayout(fig, [2, 1]);
    mainLayout.RowHeight = {380, '1x'}; 

    % --- 3. Top Row: Figures Side-by-Side ---
    figLayout = uigridlayout(mainLayout, [1, 2]);
    figLayout.ColumnWidth = {'1.2x', '1x'};

    ax2D = uiaxes(figLayout); 
    title(ax2D, 'XZ Plane B-Field Magnitude');
    axAxial = uiaxes(figLayout); 
    title(axAxial, 'Axial Magnetic Field (Bz)');
    grid(axAxial, 'on');

    % --- 4. Bottom Row: Fixed Control Area ---
    controlCont = uipanel(mainLayout, 'Title', 'Coil Control Grid (Amps)', 'Scrollable', 'on');
    
    % We use a grid with 2 rows: Row 1 for Button, Row 2 for the Coils
    numCols = 5; 
    numRows = ceil(numCoils / numCols);
    
    % Total Grid includes 1 extra row for the button
    outerGrid = uigridlayout(controlCont, [2, 1]);
    outerGrid.RowHeight = {30, '1x'}; 
    outerGrid.Padding = [10 5 10 5];

    % Small Reset Button in Row 1
    btn = uibutton(outerGrid, 'Text', 'RESET TO DEFAULTS', ...
        'FontSize', 9, 'FontWeight', 'bold');
    btn.Layout.Row = 1;
    btn.Layout.Column = 1;
    btn.ButtonPushedFcn = @(src, event) loadDefaultsAction();

    % The Coil Entry Grid in Row 2
    gridCont = uigridlayout(outerGrid, [numRows, numCols * 2]);
    gridCont.Layout.Row = 2;
    gridCont.Layout.Column = 1;
    gridCont.ColumnWidth = repmat({'1x', 60}, 1, numCols);
    gridCont.RowHeight = repmat({22}, 1, numRows); 
    gridCont.RowSpacing = 2;

    editFields = cell(numCoils, 1);

    % --- 5. Generate Entries (Fixed for Compatibility) ---
    for i = 1:numCoils
        r = ceil(i / numCols);
        c = mod(i-1, numCols); 
        
        lbl = uilabel(gridCont, 'Text', coilNames{i}, 'FontSize', 8, ...
            'HorizontalAlignment', 'right', 'FontWeight', 'bold');
        lbl.Layout.Row = r;
        lbl.Layout.Column = c*2 + 1;
        
        editFields{i} = uieditfield(gridCont, 'numeric', 'Value', 0, 'FontSize', 8);
        editFields{i}.Layout.Row = r;
        editFields{i}.Layout.Column = c*2 + 2;
        editFields{i}.ValueChangedFcn = @(src, event) updatePlotsAction();
    end

    % --- 6. Logic with Handwritten Values ---
    function loadDefaultsAction()
        % values from your notebook
        defaults = struct(...
            'Coil_11', 168.0, ...
            'Coil10_5T', 11.86, ...
            'Coil12_1Tmain', 84.0, ...
            'Corrector_Coil1_5T', 11.86, ...
            'Corrector_Coil2_5T', 5.0, ...
            'Corrector_Coil3_5T', 2.94, ...
            'Corrector_Coil4_5T', 0.63, ...
            'Corrector_Coil8_5T', 2.2, ...
            'Corrector_Coil13_1T', 1.3, ...
            'Corrector_Coil14_1T', 1.91, ...
            'Corrector_Coil15_1T', 1.36, ...
            'Corrector_Coil16_1T', 0.29, ...
            'Corrector_Coil17_1T', 0.37, ...
            'Corrector_Coil18_1T', 1.12, ...
            'Corrector_Coil19_1T', 0.32, ...
            'Corrector_Coil20_1T', 3.8, ...
            'Corrector_Coil22_1T', 6.22, ...
            'Corrector_Coil23_1T', 8.0);

        for k = 1:numCoils
            name = coilNames{k};
            if isfield(defaults, name)
                editFields{k}.Value = defaults.(name);
            else
                editFields{k}.Value = 0;
            end
        end
        updatePlotsAction();
    end

    function updatePlotsAction()
        Bz_total = zeros(size(MasterGrid.Z));
        Bx_total = zeros(size(MasterGrid.Z));
        By_total = zeros(size(MasterGrid.Z));

        for k = 1:numCoils
            val = editFields{k}.Value;
            Bz_total = Bz_total + UnitFields.(coilNames{k}).Bz * val;
            Bx_total = Bx_total + UnitFields.(coilNames{k}).Bx * val;
            By_total = By_total + UnitFields.(coilNames{k}).By * val;
        end
        B_mag = sqrt(Bx_total.^2 + By_total.^2 + Bz_total.^2);

        [ZZ, YY] = meshgrid(unique(MasterGrid.Z), unique(MasterGrid.Y));
        B_grid = griddata(MasterGrid.Z, MasterGrid.Y, B_mag, ZZ, YY);
        
        cla(ax2D);
        if max(B_grid(:)) > 1e-6
            contourf(ax2D, ZZ, YY, B_grid, 20, 'EdgeColor', 'none');
            colormap(ax2D, 'turbo'); colorbar(ax2D);
        end

        [~, cIdx] = min(abs(MasterGrid.Y));
        axialMask = (MasterGrid.Y == MasterGrid.Y(cIdx));
        z_s = MasterGrid.Z(axialMask); bz_s = Bz_total(axialMask);
        [z_sorted, sIdx] = sort(z_s);
        
        plot(axAxial, z_sorted, bz_s(sIdx), 'LineWidth', 2, 'Color', [0.1 0.4 0.7]);
        grid(axAxial, 'on');
    end

    loadDefaultsAction(); 
end