function linfGUI()
hFigure = figure;
init_toolbar();
hToolbar = findall(hFigure,'Type','uitoolbar');
% Make next grid button
make_icon = imresize(imread('make.png'),[16 16]);
uitoggletool(hToolbar, ...
    'ClickedCallback', @toggle_make_callback, ...
    'CData', make_icon, ...
    'TooltipString','Paint truth and annotations', ...
    'Tag','make_clust');
jToolbar = get(get(hToolbar,'JavaContainer'),'ComponentPeer');
uistate = struct;
uistate.handles = guihandles(hFigure);
if ~isempty(jToolbar)
    jCombo = javax.swing.JComboBox();
    uistate.handles.make_clust = handle(jCombo,'CallbackProperties');
    set(uistate.handles.make_clust, 'Visible', 0);
    set(uistate.handles.make_clust, 'ActionPerformedCallback', @toggle_make_callback);
    jToolbar(1).add(jCombo,1); % 1 icon after pan icon
    jToolbar(1).repaint;
    jToolbar(1).revalidate;
end
set(0,'showhiddenhandles','on');

cfg = CFG.get();
init_dbs();
uistate.sqldb = SQL.SqlDb.getObj();
uistate.img_set = uistate.sqldb.get_img_set(cfg.img_set.img_set);
guidata(gcf,uistate);


function [] = open_file_callback(hObject, eventdata)
% hObject    handle to OpenMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
uistate = guidata(gcf);
figure();
axes('Units','pixels');
popup = uicontrol('Style', 'listbox',...
       'String', {uistate.img_set(:).url},...
       'Position', [1 1 1000 420],...
       'Callback', @process_image);
guidata(gcf,uistate);


function process_image(source,callbackdata)
uistate = guidata(gcf);
uistate.cur_image = get(source,'Value');
close; % close popup
k = uistate.cur_image;
uistate.cache = CASS.CidCache(uistate.img_set(k).cid);
uistate.img = Img('data',uistate.cache.get_img(), ...
                     'cid',uistate.img_set(k).cid, ...
                     'url',uistate.img_set(k).url);
uistate.cache.add_dependency('planar_regions',[]);
uistate.plane_list = uistate.cache.get('annotations','planar_regions');

uistate.handles.img = image(uistate.img.data);
mpdc = distinguishable_colors(numel(uistate.plane_list));
for k2 = 1:numel(uistate.plane_list)
    for k3 = 1:numel(uistate.plane_list(k2).repeat_list)
        for k4 = 1:numel(uistate.plane_list(k2).repeat_list(k3).poly)
            hold on;
            if (uistate.plane_list(k2).repeat_list(k3).poly(k4).is_grid)
                color = 0.5*mpdc(k2,:);
            else
                color = mpdc(k2,:);
            end
            u = uistate.plane_list(k2).repeat_list(k3).poly(k4).x;
            plot(gca,[u(1,:) u(1,1)], [u(2,:) u(2,1)], ...
                 'Color',color,'LineWidth',3);
            mu = [sum(u(1,:))/4; sum(u(2,:))/4];
            text(mu(1,:)',mu(2,:)', ...
                 num2str(k2), ...
                 'Color',color);
            hold off;
        end
    end
end
uistate.buffer = [];
set(uistate.handles.img,'HitTest','on');
set(uistate.handles.img,'ButtonDownFcn',@image_click_callback);
guidata(gcf,uistate);


function [] = save_file_callback(hObject, eventdata)
uistate = guidata(gcf);
uistate.cache.put('annotations','planar_regions',uistate.plane_list);
disp('Saved!');
guidata(gcf, uistate);


function image_click_callback(hImg, eventdata)
uistate = guidata(gcf);
axesHandle = get(hImg,'Parent');
point = get(axesHandle,'CurrentPoint');
point = point(1,1:2);
id = get_plane_id(uistate.plane_list,point);
id
uistate.buffer = [uistate.buffer id];
guidata(gcf,uistate);


function id = get_plane_id(plane_list,point)
id = 0;
for k1 = 1:numel(plane_list)
  for k2 = 1:numel(plane_list(k1).repeat_list)
    for p = 1:numel(plane_list(k1).repeat_list(k2).poly)
      polyg = plane_list(k1).repeat_list(k2).poly(p).x;
      polyg = cat(2,polyg,polyg(:,1));
      in = any(inpolygon(point(1),point(2), ...
                      polyg(1,:),polyg(2,:)));
      if(in)
        id = k1;
        return;
      end
    end
  end
end


function toggle_make_callback(hCombo, eventdata)
uistate = guidata(gcf);
uistate.buffer = setdiff(unique(uistate.buffer),0);
uistate.buffer
[uistate.plane_list(uistate.buffer).common_linf] = deal(uistate.buffer);
uistate.buffer = [];
disp('Buffer cleaned.');
guidata(gcf, uistate);


function init_toolbar()
a = findall(gcf);
b = findall(a,'ToolTipString','Rotate 3D');
set(b,'Visible','Off');

% b = findall(a,'ToolTipString','Brush/Select Data');
% set(b,'Visible','Off');

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

function edges = find_edges(polys);
    x = polys(1,:);
    y = polys(2,:);
    edges = [];
    edges = cat(2,edges,[polys(:,1); 1]);
    edges = cat(2,edges,[polys(:,end-1); 1]);
    [m,n] = size_of_grid(polys);
    edges = cat(2,edges,[polys(:,4*(m-1)+2); 1]);
    edges = cat(2,edges,[polys(:,end-4*(m-1)); 1]);

function [m,n] = size_of_grid(polys)
    m = 1;
    t = 1;
    p = 0;
    n = 0;
    while p <= size(polys,2)-8
        while p <= size(polys,2)-8 & polys(:,p + 2) == polys(:,p+5) & ...
                                  polys(:,p + 3) == polys(:,p+8) 
            p = p + 4;
            t = t + 1;
            if t > m, m = t; end
        end
        t = 1;
        p = p + 4;
        n = n + 1;
    end
    if p <= size(polys,2)-4
        n = n + 1;
    end
