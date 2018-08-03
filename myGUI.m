function myGUI()
% Create the figure window and show the image.
hFigure = figure;

init_toolbar();

hToolbar = findall(hFigure,'Type','uitoolbar');

plane_icon = imresize(imread('plane.jpg'),[16 16]);
repeat_icon = imresize(imread('repeat.png'),[16 16]);
grid_icon = zeros(16,16);
grid_icon(:,2:3:16) = 1;
grid_icon(2:3:16,:) = 1;
grid_icon = repmat(grid_icon,[1 1 3]);
symmetry_icon = imresize(imread('symmetry.png'),[16 16]);

% Add a toolbar button for 90deg clockwise rotation
uipushtool('Parent', hToolbar, ...
    'ClickedCallback', @add_plane, ...
    'CData', plane_icon, ...
    'TooltipString','Add scene plane','Tag','add_plane');

uipushtool('Parent', hToolbar, ...
    'ClickedCallback', @add_repeat, ...
    'CData', repeat_icon, ...
    'TooltipString','Add repeating scene element', ...
    'Tag','add_repeat');

uitoggletool(hToolbar,'CData',grid_icon, ...
    'ClickedCallback', @toggle_grid_callback, ...
    'TooltipString','Toggle selction method between grid and polyline', ...
    'Tag','toggle_grid');

h = uitoggletool(hToolbar,'CData',symmetry_icon, ...
    'ClickedCallback', @toggle_symmetry_callback, ...
    'TooltipString','Set axial symmetry for this repeat', ...
    'Tag','toggle_symmetry');

uistate = struct;
uistate.handles = guihandles(hFigure);
uistate.handles.sym_button = h;

jToolbar = get(get(hToolbar,'JavaContainer'),'ComponentPeer');
if ~isempty(jToolbar)
    jCombo = javax.swing.JComboBox();
    uistate.handles.select_plane = handle(jCombo,'CallbackProperties');
    set(uistate.handles.select_plane, 'Visible', 0);
    set(uistate.handles.select_plane, 'ActionPerformedCallback', @select_plane_callback);

    jToolbar(1).add(jCombo,5); %5th position, after printer icon
    jToolbar(1).repaint;
    jToolbar(1).revalidate;
end

if ~isempty(jToolbar)
    jCombo = javax.swing.JComboBox();
    uistate.handles.select_repeat = handle(jCombo,'CallbackProperties');
    set(uistate.handles.select_repeat, 'Visible', 0);
    set(uistate.handles.select_repeat, 'ActionPerformedCallback', @select_repeat_callback);
    
    jToolbar(1).add(jCombo,6); %6th position, after printer icon
    jToolbar(1).repaint;
    jToolbar(1).revalidate;
end

uistate.grid_flag = 0;
uistate.sym_flag = 0;

guidata(gcf,uistate);

function uistate = update_select_plane()
uistate = guidata(gcf);
num_planes = numel(uistate.plane_list);
uistate.handles.select_plane.removeAllItems();

for k = 1:num_planes
    uistate.handles.select_plane.addItem(['Plane ' num2str(k)]);
end

uistate.handles.select_plane.addItem('Outlier');
uistate.handles.select_plane.addItem('Ignore');

if num_planes > 0
   set(uistate.handles.select_plane,'Visible',1); 
   uistate.handles.select_plane.setSelectedIndex(uistate.cur_plane-1);
else
   set(uistate.handles.select_plane,'Visible',0);     
end
guidata(gcf,uistate);
update_select_repeat();

function uistate = update_select_repeat()
uistate = guidata(gcf);
uistate.handles.select_repeat.removeAllItems();
if ~uistate.outlier.select && ~uistate.ignore.select
    num_repeats = numel(uistate.plane_list{uistate.cur_plane});
    for k = 1:num_repeats
        uistate.handles.select_repeat.addItem(['Repeat ' num2str(k)]);
    end

    if num_repeats > 0
       set(uistate.handles.select_repeat,'Visible',1); 
       uistate.handles.select_repeat.setSelectedIndex(uistate.cur_repeat(uistate.cur_plane)-1);
    else
       set(uistate.handles.select_repeat,'Visible',0);     
    end
end
guidata(gcf,uistate);

function uistate = add_plane(hButton, eventdata)
uistate = guidata(gcf);
uistate.plane_list{numel(uistate.plane_list)+1} = [];
num_planes = numel(uistate.plane_list);
uistate.cur_plane = num_planes;
guidata(gcf,uistate);
update_select_plane();
uistate = add_repeat([],[]);
guidata(gcf,uistate);

function uistate = add_repeat(hButton, eventdata)
uistate = guidata(gcf);
if isempty(uistate.plane_list{uistate.cur_plane})
    uistate.plane_list{uistate.cur_plane} = struct('h',[],'symmetric',false,'is_grid',[]);
else
    uistate.plane_list{uistate.cur_plane} = cat(2,uistate.plane_list{uistate.cur_plane},struct('h',[],'symmetric',false,'is_grid',[]));
        
end
uistate.cur_repeat(uistate.cur_plane) = numel(uistate.plane_list{uistate.cur_plane});
if uistate.sym_flag == 1
    set(uistate.handles.sym_button, 'State', 'off');
end

uistate.number_of_grids{uistate.cur_plane, uistate.cur_repeat(uistate.cur_plane)} = 0;

guidata(gcf,uistate);
update_select_repeat();
guidata(gcf,uistate);

function [] = open_file_callback(hObject, eventdata)
% hObject    handle to OpenMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
uistate = guidata(gcf);

    
[file_name,path] = uigetfile({'*.png;*.jpg;*.gif;*.JPG','Pictures (*.png,*.jpg,*.gif)';'*.mat', 'Repeats (*.mat)'});

if ~isequal(file_name, 0)
    [~,uistate.file_name_base,file_name_end] = fileparts(file_name);  
    if isequal(file_name_end, '.mat') 
        load([path file_name]);
        uistate.handles.img = imshow(imread([path ann.file_name]),'Parent',gca);    axis off;
        set(uistate.handles.img,'HitTest','on');
        set(uistate.handles.img,'ButtonDownFcn',@image_click_callback);
        uistate.plane_list = ann.plane_list;
        uistate.cur_plane = ann.cur_plane;
        uistate.cur_repeat = ann.cur_repeat;
        uistate.file_name = ann.file_name;
        uistate.path = ann.path;
        uistate.number_of_grids = ann.number_of_grids;
        uistate.outlier = ann.outlier;
        uistate.ignore = ann.ignore;
        num_planes = numel(uistate.plane_list);
        for i = 1:num_planes
           num_repeats = numel(uistate.plane_list{i});
           for j = 1:num_repeats       
                num_items = numel(uistate.plane_list{i}(j).h);
                if num_items > 0 
                    temp = ann.plane_list{i}(j).h;
                    uistate.plane_list{i}(j).h = [];
                    for k = 1:num_items
                        h = impoly(gca, temp{k});
                        uistate.plane_list{i}(j).h = cat(2, ...
                             uistate.plane_list{i}(j).h,h); 
                    end
                end
           end
        end
        
        if iscell(uistate.outlier.h)
          h = uistate.outlier.h;
          for i = 1:numel(h)
              uistate.outlier.h(i) = impoly(gca, h{i});
          end
        else
          for i = 1:numel(uistate.outlier.h)
              if isvalid(uistate.outlier.h(i))
                  uistate.outlier.h(i) = impoly(gca, getPosition(uistate.outlier.h(i)));
              else 
                  uistate.outlier.h(i) = [];
              end
          end
        end
        
        if iscell(uistate.ignore.h)
          h = uistate.ignore.h;
          for i = 1:numel(h)
              uistate.ignore.h(i) = impoly(gca, h{i});
          end
        else
          for i = 1:numel(uistate.ignore.h)
              uistate.ignore.h(i) = impoly(gca, getPosition(uistate.ignore.h(i)));
          end
        end
          
        guidata(gcf,uistate);
        update_select_plane();
        update_select_repeat();
        uistate = guidata(gcf);
    else
        uistate.handles.img = imshow(imread([path file_name]),'Parent',gca);    axis off;
        set(uistate.handles.img,'HitTest','on');
        set(uistate.handles.img,'ButtonDownFcn',@image_click_callback);
        uistate.plane_list = cell(1,0);
        uistate.cur_plane = 0;
        uistate.cur_repeat(1) = 0;
        uistate.number_of_grids = cell(1,0);
        uistate.file_name = file_name;
        uistate.path = path;
        uistate.outlier = struct('h',[],'select',false);
        uistate.ignore = struct('h',[],'select',false);
        guidata(gcf,uistate); 
        uistate = add_plane([],[]);
    end;
end

guidata(gcf,uistate);

function [] = save_file_callback(hObject, eventdata)
uistate = guidata(gcf);
uistate.path = '/mnt/home/rozumden/src/gtrepeat/dggt/';
[file,path] = uiputfile([uistate.file_name_base '.mat'],'Save file name');
if ~isequal(file, 0)
    ann.plane_list = uistate.plane_list;
    ann.cur_plane = uistate.cur_plane;
    ann.cur_repeat = uistate.cur_repeat;
    ann.file_name = uistate.file_name;
    ann.path = uistate.path;
    ann.number_of_grids = uistate.number_of_grids; 
    ann.outlier = uistate.outlier;
    ann.ignore = uistate.ignore;
    for i = 1:numel(ann.plane_list)
        for j = 1:numel(ann.plane_list{i})
            temp = ann.plane_list{i}(j).h;
            ann.plane_list{i}(j).h = cell(1,numel(temp));
            for k = 1:numel(temp)
                ann.plane_list{i}(j).h{k} = getPosition(temp(k));
            end
        end
    end
    save([path file], 'ann');

    cfg = CFG.get();
    [sqldb,imagedb] = get_dbs(get_dbs_cfg());

    putname = [uistate.path uistate.file_name];
    h = '';
    if ~sqldb.check_img(putname)
        filecontent = getimage(putname);
        h = hash(filecontent, 'MD5');
        imagedb.put('image',h,'raw',filecontent);
        sqldb.put_img(h,putname);
        sqldb.put_img_set(cfg.img_set.img_set,{putname});
    else 
        h = sqldb.get_img_cid(putname);
    end
    cache = CASS.CidCache(h);
    put_cass(cache,ann);
    disp(['Put in database ' file]);
end

guidata(gcf, uistate);

function image_click_callback(hImg, eventdata)
uistate = guidata(gcf);
if isempty(uistate.plane_list)
    uistate = add_plane([],[]);
end

if uistate.outlier.select || uistate.ignore.select
    h = impoly(gca); 
    if uistate.outlier.select
        uistate.outlier.h = cat(2, uistate.outlier.h, h);
    else
        uistate.ignore.h = cat(2, uistate.ignore.h, h);
    end
else
    if uistate.grid_flag == 1
        click_grid(); 
        uistate = guidata(gcf);
    else
        h = impoly(gca); 
        is_grid = 0;
        uistate.plane_list{uistate.cur_plane}(uistate.cur_repeat(uistate.cur_plane)).h = cat(2, ...
            uistate.plane_list{uistate.cur_plane}(uistate.cur_repeat(uistate.cur_plane)).h,h); 

        uistate.plane_list{uistate.cur_plane}(uistate.cur_repeat(uistate.cur_plane)).is_grid = cat(2, ...
            uistate.plane_list{uistate.cur_plane}(uistate.cur_repeat(uistate.cur_plane)).is_grid,is_grid);
    end
end
guidata(gcf,uistate);

function select_plane_callback(hCombo, eventdata)
uistate = guidata(gcf);
item = uistate.handles.select_plane.getSelectedIndex()+1;
uistate.cur_plane = item;
if item <= numel(uistate.plane_list)
    uistate.outlier.select = false;
    uistate.ignore.select = false;
    num_repeats = numel(uistate.plane_list{uistate.cur_plane});
    if num_repeats > 0
        set(uistate.handles.select_repeat, 'Visible', 1);
    else
        set(uistate.handles.select_repeat, 'Visible', 0);
    end
else
    if item == numel(uistate.plane_list) + 1
        uistate.ignore.select = false;
        uistate.outlier.select = true;
    else
        uistate.outlier.select = false;
        uistate.ignore.select = true;
    end
end
guidata(gcf,uistate);
show_cur_repeats();
update_select_repeat();

function select_repeat_callback(hCombo, eventdata)
uistate = guidata(gcf);
item = uistate.handles.select_repeat.getSelectedIndex()+1;
uistate.cur_repeat(uistate.cur_plane) = item; 

guidata(gcf,uistate);
show_cur_repeats();
guidata(gcf,uistate);

function toggle_grid_callback(hCombo, eventdata)
uistate = guidata(gcf);

if uistate.grid_flag == 0
    uistate.grid_flag = 1;
else
    uistate.grid_flag = 0;
end
guidata(gcf, uistate);

function toggle_symmetry_callback(hCombo, eventdata)
uistate = guidata(gcf);
  if uistate.sym_flag == 1
      uistate.sym_flag = 0;
      if uistate.plane_list{uistate.cur_plane}(uistate.cur_repeat(uistate.cur_plane)).symmetric == true
          uistate.plane_list{uistate.cur_plane}(uistate.cur_repeat(uistate.cur_plane)).symmetric = false;     
      end
  else
      uistate.sym_flag = 1;
      if uistate.plane_list{uistate.cur_plane}(uistate.cur_repeat(uistate.cur_plane)).symmetric == false
          uistate.plane_list{uistate.cur_plane}(uistate.cur_repeat(uistate.cur_plane)).symmetric = true;     
      end
  end
  
guidata(gcf, uistate);

function click_grid()
uistate = guidata(gcf);
grid_parameters = inputdlg({'Number of rows','Number of columns'}, 'Parameters of grid', 1);

if isempty(grid_parameters) || isempty(grid_parameters{1}) || isempty(grid_parameters{2})
    return;
end

m = str2num(grid_parameters{1});
n = str2num(grid_parameters{2});

h = impoly(gca);
pos = getPosition(h);
   if size(pos,1) ~= 4
      errordlg('Polygon must be quadrilateral');
      delete(h);
      return;
   end
can = [0 1 1 0; 0 0 1 1; 1 1 1 1];
  p = [pos'; 1 1 1 1];
  
  H = u2H(can, p);

  dn = [0:n] / n;
  dm = [0:m] / m;
  n0 = zeros(1,n);
  m0 = zeros(1,m);
  n1 = ones(1,n);
  m1 = ones(1, m);

  %keyboard

  pts = [dn(1:end-1), m1, dn(end:-1:2), m0;
         n0, dm(1:end-1), n1, dm(end:-1:2);
         n1, m1, n1, m1];

  ptstr = H * pts;
  polyg = [ptstr(1,:) ./ ptstr(3,:); ptstr(2,:) ./ ptstr(3,:)];
  polyg(3,:) = 1;

  delete(h);

%  h2 = impoly(gca, polyg');
%  wait(h2);

h  = cell(1,0);

for i = 1:n
  c1 = cross (polyg(:,i), polyg(:,end-m-i+2));
  c2 = cross (polyg(:,i+1), polyg(:,end-m-i+1));
   for j = 1:m
    if j == 1
      r1 = cross (polyg(:,1), polyg(:,n+j));
    else
      r1 = cross (polyg(:,end-j+2), polyg(:,n+j)); 
    end
    r2 = cross (polyg(:,end-j+1), polyg(:,n+j+1));

   p = cross([c1, c1, c2, c2],[r1, r2, r2, r1]);
   p = p ./ repmat(p(3,:),3,1);

  h{i,j} = impoly(gca, p(1:2,:)');
  

   end
end
cont = inputdlg('Continue?(y/n)');
if isequal(cont{1} ,'y')
    uistate.number_of_grids{uistate.cur_plane, uistate.cur_repeat(uistate.cur_plane)} = ...
    uistate.number_of_grids{uistate.cur_plane, uistate.cur_repeat(uistate.cur_plane)} + 1;
    is_grid = uistate.number_of_grids{uistate.cur_plane, uistate.cur_repeat(uistate.cur_plane)};
    for i = 1:n
        for j = 1:m
            
             uistate.plane_list{uistate.cur_plane}(uistate.cur_repeat(uistate.cur_plane)).h = cat(2, ...
                uistate.plane_list{uistate.cur_plane}(uistate.cur_repeat(uistate.cur_plane)).h,h{i,j}); 
    
             uistate.plane_list{uistate.cur_plane}(uistate.cur_repeat(uistate.cur_plane)).is_grid = cat(2, ...
                  uistate.plane_list{uistate.cur_plane}(uistate.cur_repeat(uistate.cur_plane)).is_grid,is_grid);
        end
    end   
else
    for i = 1:n
        for j = 1:m
            delete(h{i,j});
        end
    end
end

guidata(gcf, uistate);

function H = u2H(u,u0)
if size(u,1) == 2
u = [u;ones(1,size(u,2))];
u0 = [u0;ones(1,size(u0,2))];
end

m = size(u,2);
z = zeros(m,3);
M = [u' z bsxfun(@times,-u0(1,:),u)'; ...
z u' bsxfun(@times,-u0(2,:),u)'];
[U S V] = svd(M);
H = reshape(V(:,end),3,3)';

function show_cur_repeats()
uistate = guidata(gcf);
num_planes = numel(uistate.plane_list);
if uistate.outlier.select || uistate.ignore.select
    
    if uistate.outlier.select
        
        for i = 1:numel(uistate.ignore.h)
            set(uistate.ignore.h(i), 'Visible', 'off');
        end
        
        for i = 1:numel(uistate.outlier.h)
            set(uistate.outlier.h(i), 'Visible', 'on');
        end
    else
        for i = 1:numel(uistate.ignore.h)
            set(uistate.ignore.h(i), 'Visible', 'on');
        end
        
        for i = 1:numel(uistate.outlier.h)
            set(uistate.outlier.h(i), 'Visible', 'off');
        end
    end
    
    for i = 1:num_planes
        num_repeats = numel(uistate.plane_list{i});
        for j = 1:num_repeats       
            num_items = numel(uistate.plane_list{i}(j).h);
            if num_items > 0
                for k = 1:num_items
                    set(uistate.plane_list{i}(j).h(k), 'Visible', 'off');
                end
            end
        end
    end
    
else
    for i = 1:num_planes
        num_repeats = numel(uistate.plane_list{i});
        for j = 1:num_repeats       
            num_items = numel(uistate.plane_list{i}(j).h);
            if num_items > 0
                for k = 1:num_items
                    if i == uistate.cur_plane && j == uistate.cur_repeat(uistate.cur_plane)
                        set(uistate.plane_list{i}(j).h(k), 'Visible', 'on');
                    else
                        set(uistate.plane_list{i}(j).h(k), 'Visible', 'off');
                    end
                end
            end
        end
    end
    
    if uistate.plane_list{uistate.cur_plane}(uistate.cur_repeat(uistate.cur_plane)).symmetric == true 
         set(uistate.handles.sym_button, 'State', 'on');  
         uistate.sym_flag = 1;
    else
        if uistate.plane_list{uistate.cur_plane}(uistate.cur_repeat(uistate.cur_plane)).symmetric == false
             set(uistate.handles.sym_button, 'State', 'off'); 
             uistate.sym_flag = 0;
        end
    end

    for i = 1:numel(uistate.outlier.h)
        set(uistate.outlier.h(i), 'Visible', 'off');
    end    
    
    for i = 1:numel(uistate.ignore.h)
        set(uistate.ignore.h(i), 'Visible', 'off');           
    end
    
end
guidata(gcf, uistate);

function init_toolbar()
a = findall(gcf);
b = findall(a,'ToolTipString','Rotate 3D');
set(b,'Visible','Off');

b = findall(a,'ToolTipString','Brush/Select Data');
set(b,'Visible','Off');

b = findall(a,'ToolTipString','Rotate 3D');
set(b,'Visible','Off');

b = findall(a,'ToolTipString','Insert Colorbar');
set(b,'Visible','Off');

b = findall(a,'ToolTipString','Insert Legend');
set(b,'Visible','Off');

b = findall(a,'ToolTipString','Link Plot');
set(b,'Visible','Off');

b = findall(a,'ToolTipString','Print Figure');
set(b,'Visible','Off');

b = findall(a,'ToolTipString','Hide Plot Tools');
set(b,'Visible','Off');

b = findall(a,'ToolTipString','Show Plot Tools');
set(b,'Visible','Off');

b = findall(a,'ToolTipString','Show Plot Tools and Dock Figure');
set(b,'Visible','Off');

b = findall(a,'ToolTipString','Edit Plot');
set(b,'Visible','Off');

b = findall(a,'ToolTipString','Data Cursor');
set(b,'Visible','Off');

b = findall(a,'ToolTipString','Open File');
set(b,'ClickedCallback',@open_file_callback);

b = findall(a,'ToolTipString','Save Figure');
set(b,'ClickedCallback',@save_file_callback);






