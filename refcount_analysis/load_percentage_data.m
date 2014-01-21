
function [hhvmclean, hhvmbump, hhvmbumpnocount] = load_percentage_data()
    %   Detailed explanation goes here
    persistent data_set
    if isempty(data_set)
        data_set = load_bench_dict();
    end
%Lazy way to extract all the datasets from their cells
    hhvmclean = data_set('hhvmclean');
    hhvmclean = hhvmclean{1};
    hhvmbump = data_set('hhvmbump');
    hhvmbump = hhvmbump{1};
    hhvmbumpnocount = data_set('hhvmbumpnocount');
    hhvmbumpnocount = hhvmbumpnocount{1};
end

function [ whole_dataset ] = load_bench_dict( input_args )
%Loads the percentage of requests/response time data for all benchmarks
%   returns Map('benchmark'){(no_reqs, no_conc, percentage+1)}
    whole_dataset = containers.Map();
    benchmarks = {'hhvmclean', 'hhvmbump', 'hhvmbumpnocount'}; %omit hhvmnocount
    for benchmark = benchmarks
        whole_dataset(benchmark{1}) = {load_bench_data(benchmark{1})}; %use {1} due to cell iteration
    end
end

function [ results ] = load_bench_data(benchmark)
%Iterates through all results for a particular benchmark and collates them
%   returns [(no_reqs/200, no_conc/40, percentage, responsetime);]
    results = double(NaN(8,10,100));
   
    for req = 200:200:1600
        for conc = 40:40:400
            if conc > req
                continue
            end
            for percentage = 1:1:100
                csv = load_result_csv(benchmark, req, conc);
                results(req/200, conc/40, percentage) = csv(percentage, 2);
            end
        end
    end
end

function [loaded_csv] = load_result_csv(bench, req, conc)
%Loads the response time data from the apache-bench .csv's
%   returns [(percentage, responsetime);]
    filename = strcat('results/', bench, '-n', num2str(req), '-c', num2str(conc), '.csv');
    loaded_csv = csvread(filename, 1, 0);
end
