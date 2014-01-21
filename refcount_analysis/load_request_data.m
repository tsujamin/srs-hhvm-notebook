function [hhvmclean, hhvmbump, hhvmbumpnocount] = load_request_data()
    %   Detailed explanation goes here
    persistent data_set
    if isempty(data_set)
        data_set = load_bench_dict();
    end
%Lazy way to extract all the datasets from their cells
    hhvmclean = data_set('hhvmclean');
    hhvmbump = data_set('hhvmbump');
    hhvmbumpnocount = data_set('hhvmbumpnocount');
end

function [ whole_dataset ] = load_bench_dict()
%loads the dataset as (n,c,s)
    whole_dataset = containers.Map();
    benchmarks = {'hhvmclean', 'hhvmbump', 'hhvmbumpnocount'}; %omit hhvmnocount
    for benchmark = benchmarks
        result_mat = double(NaN(8,10));
        bench_results = csvread(['results/',benchmark{1},'-requestspersecond.csv']);
        counter = 1;
        for req = 200:200:1600
            for conc = 40:40:400
            if conc > req
                continue
            end
                result_mat(req/200,conc/40) = bench_results(counter, 3);
                counter = counter + 1;
            end
        end
        whole_dataset(benchmark{1}) = result_mat;
    end
end