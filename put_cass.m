function put_cass(cache,ann)
cache.add_dependency('planar_regions',[]);
cache.add_dependency('outlier_regions',[]);
cache.add_dependency('ignore_regions',[]);

plane_list = [];
cur.ann = ann;
rmind = cellfun(@(x) isempty(x),cur.ann.plane_list);
cur.ann.plane_list(find(rmind)) = [];

for k2 = 1:numel(cur.ann.plane_list)
    rmind = arrayfun(@(x) isempty(x.h),cur.ann.plane_list{k2});
    cur.ann.plane_list{k2}(rmind) = [];
    if ~isempty(cur.ann.plane_list{k2})
        plane_list(k2).has_grid = false;
        for k3 = 1:numel(cur.ann.plane_list{k2})
            rgns = cur.ann.plane_list{k2}(k3);
            mus = zeros(2,numel(rgns.h));
            knnlist = {};
            for k4 = 1:numel(rgns.h)
                plane_list(k2).repeat_list(k3).poly(k4).x = rgns.h{k4}';
                plane_list(k2).repeat_list(k3).poly(k4).num_pts = size(plane_list(k2).repeat_list(k3).poly(k4).x,2);
                plane_list(k2).repeat_list(k3).poly(k4).mu = ...
                    mean(plane_list(k2).repeat_list(k3).poly(k4).x,2);
                plane_list(k2).repeat_list(k3).poly(k4).knn = [];
                mus(:,k4) = ...
                    plane_list(k2).repeat_list(k3).poly(k4).mu;
                plane_list(k2).repeat_list(k3).poly(k4).is_grid = false;
            end
            
            if isempty(rgns.h)
                disp(['there is an error in file ' ann.file_name]);
            end

            idx = knnsearch(mus',mus','K', ...
                            min([11 numel(rgns.h)]));
            
            knnlist(idx(:,1)) = mat2cell(idx(:,2:end), ...
                                         ones(1,size(idx,1)), ...
                                         size(idx,2)-1);            

            if isfield(rgns,'is_grid')
                ugridid = setdiff(unique(rgns.is_grid),0);
                
                for k4 = ugridid
                    ind = find(ugridid==k4);
                    
                    % try
                        idx = knnsearch(mus(:,ind)',mus(:,ind)', ...
                                        'K',min([11 numel(ind)]));
                    % catch err
                    %     disp(['!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!']);
                    %     disp(['Error in ' mat_files{k}]);
                    %     disp(['Error in  plane ']);
                    %     k2
                    %     disp(['repeat number ']);
                    %     k3
                    %     ugridid 
                    %     disp(['!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!']);
                    %     rethrow(err);
                    % end
                        
                    
                    knnlist(ind) = mat2cell(ind(:,idx(2:end)), ...
                                            ones(1,size(idx,1)), ...
                                            size(idx,2)-1);
                end
            end
            
            for k4 = 1:numel(rgns.h)
                if (isfield(rgns,'is_grid') && rgns.is_grid(k4) > 0)
                    plane_list(k2).has_grid = true;
                    plane_list(k2).repeat_list(k3).grids = rgns.is_grid;
                    plane_list(k2).repeat_list(k3).poly(k4).is_grid ...
                        = rgns.is_grid(k4);
                end
                plane_list(k2).repeat_list(k3).poly(k4).knn = ...
                    knnlist{k4};
            end
        end
    end
end

outlier = struct('poly',[]);
if isfield(cur.ann,'outlier') 
    k5 = 1;
    for k4 = 1:numel(cur.ann.outlier.h)
        if iscell(cur.ann.outlier.h)
            if ~isempty(cur.ann.outlier.h{k4})
                outlier.poly(k5).x = cur.ann.outlier.h{k4};
                k5 = k5+1;
            end
        else
            if ~isempty(cur.ann.outlier.h(k4))
                outlier.poly(k5).x = ...
                    getPosition(cur.ann.outlier.h(k4))';
                k5 = k5+1;
            end
        end
    end
end

ignore = struct('poly',[]);
if isfield(cur.ann,'ignore') 
    k5 = 1;
    for k4 = 1:numel(cur.ann.ignore.h)
        if iscell(cur.ann.ignore.h)
            if ~isempty(cur.ann.ignore.h{k4})
                ignore.poly(k5).x = cur.ann.ignore.h{k4};
                k5 = k5+1;
            end
        else
            if ~isempty(cur.ann.ignore.h(k4))
                ignore.poly(k5).x = ...
                    getPosition(cur.ann.ignore.h(k4))';
                k5 = k5+1;
            end
        end
    end
end
cache.put('annotations','planar_regions',plane_list);
cache.put('annotations','outlier_regions',outlier);
cache.put('annotations','ignore_regions',ignore);