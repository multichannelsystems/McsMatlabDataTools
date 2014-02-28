function cfg = defaultConfig(inp)
    % read default config from internal structure of McsData object
    

    cfg = [];
    
    cfg.recordings = 1:length(inp.Recording);
    cfg.recordingIDs = cellfun(@(x)(x.RecordingID),inp.Recording);
    
    cfg.analogStreams = cell(length(cfg.recordings),1);
    cfg.frameStreams = cell(length(cfg.recordings),1);
    cfg.segmentStreams = cell(length(cfg.recordings),1);
    cfg.eventStreams = cell(length(cfg.recordings),1);
    cfg.channels = cell(length(cfg.recordings),1);
    cfg.channelIDs = cell(length(cfg.recordings),1);
    cfg.windows = cell(length(cfg.recordings),1);
    
    for reci = cfg.recordings
        if ~isempty(inp.Recording{reci}.AnalogStream)
            stream = 'AnalogStream';
        elseif ~isempty(inp.Recording{reci}.FrameStream)
            stream = 'FrameStream';
        elseif ~isempty(inp.Recording{reci}.EventStream)
            stream = 'EventStream';
        elseif ~isempty(inp.Recording{reci}.SegmentStream)
            stream = 'SegmentStream';
        else
            error('No stream found!')
        end
        cfg.streams{reci} = 1:length(inp.Recording{reci}.(stream));
        
        cfg.channels{reci} = cell(length(inp.Recording{reci}.(stream)),1);
        cfg.channelIDs{reci} = cell(length(inp.Recording{reci}.(stream)),1);
        cfg.windows{reci} = zeros(length(inp.Recording{reci}.(stream)),2);
        
        for stri = cfg.streams{reci}
            if ~isempty(inp.Recording{reci}.AnalogStream)
                cfg.channels{reci}{stri} = 1:inp.Recording{reci}.AnalogStream{stri}.ChannelData.Size(2);
                cfg.channelIDs{reci}{stri} = 1:double(inp.Recording{reci}.(stream){stri}.Info.ChannelID);
                cfg.windows{reci}(stri,:) = [1 inp.Recording{reci}.(stream){stri}.ChannelData.Size(1)];
            elseif ~isempty(inp.Recording{reci}.FrameStream)
                cfg.channels{reci}{stri} = true(inp.Recording{reci}.FrameStream{stri}.Info.FrameRight - ...
                                            inp.Recording{reci}.FrameStream{stri}.Info.FrameLeft + 1, ...
                                            inp.Recording{reci}.FrameStream{stri}.Info.FrameBottom - ...
                                            inp.Recording{reci}.FrameStream{stri}.Info.FrameTop + 1);
                cfg.channelIDs{reci}{stri} = 1:numel(cfg.channels{reci}{stri});
                cfg.entities{reci}{stri} = 1:length(inp.Recording{reci}.FrameStream{stri}.FrameData);
                %cfg.windows{reci}{stri} = cell(length(inp.Recording{reci}.FrameStream
                %for enti
            end
        end
    end