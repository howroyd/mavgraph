clc
clear all

%% Get log file
[FileName,PathName,FilterIndex] = uigetfile(...
    'C:\Users\Simon\Dropbox\PhD\Flight tests\*.csv','MAVLink csv file',...
    'MultiSelect','on');

if iscell(FileName)
    numfiles = size(FileName,2);
else
    numfiles = 1;
end

for f=1:numfiles
    timeStart = cputime;
    
    if iscell(FileName)
        fid = fopen(strcat(PathName,FileName{f}));
        file = textscan(fid,'%s','delimiter','\n');
        fclose(fid);
        disp(strcat('Decoding ./',FileName{f}));
    else
        fid = fopen(strcat(PathName,FileName));
        file = textscan(fid,'%s','delimiter','\n');
        fclose(fid);
        disp(strcat('Decoding ./',FileName));
    end
    %clear fid PathName FileName FilterIndex ans

    %% Decode file & packetise
    data = struct;
    for x=1:size(file{1,1},1)
        oldline = file{1,1}{x,1};

        for y=1:length(strfind(oldline,','))
            [newline{y},oldline] = strtok(oldline,',');
        end

        try
            len = size(data.(newline{8}),1) + 1;
        catch
            len = 1;
        end

        for z=1:size(newline,2)
            data.(newline{8}){len,z} = newline{z};
        end
        % all packets IDs are now listed as a variable in the "data" structure
    end
    timeFile = cputime-timeStart;
    disp(strcat('File decoded (',num2str(timeFile,0),'secs)'));
    disp('Now decoding packets...');
    %clearvars -except data

    %% Decode packets
    packetlist = fieldnames(data);
    for x=1:size(packetlist,1) % find variable in structure
        thispacket = data.(packetlist{x});
        for y=1:size(thispacket,1) % find next row in variable
            thisline = thispacket(y,:);

            % time of row in serial format
            try
                time = datenum(strrep(thisline(1,1),'T',' '),'yyyy-mm-dd HH:MM:SS.FFF');
                name = thisline{8};
                if size(name,2) <= 1
                    continue
                end
            catch
                continue
            end

            for z=9:2:size(thisline,2)
                try
                    out.(name).(thisline{z})(y,1) = double(time);
                    out.(name).(thisline{z})(y,2) = str2double(thisline(z+1));
                catch
                    continue;
                end
            end
        end
    end
    %clearvars -except out
    timeDecode = cputime-timeFile;
    disp(strcat('Packets decoded (',num2str(timeDecode,0),'secs)'));

    %% Save
    if iscell(FileName)
        save(strrep(FileName{f},'csv','mat'),'-struct','out');
        disp(strcat('Saved to ./',FileName{f},', (',num2str(cputime-timeStart,0),'secs total)'));
    else
        save(strrep(FileName,'csv','mat'),'-struct','out');
        disp(strcat('Saved to ./',FileName,', (',num2str(cputime-timeStart,0),'secs total)'));
    end
%% End
end
clear all
disp "Done!"
