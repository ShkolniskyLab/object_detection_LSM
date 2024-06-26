function dname=tempmrcdir(key,tmpdir)
%
% TEMPMRCDIR Get teroprary directory
%
%   dname=tempmrcdir
%       Returns a temporary directory name for ASPIRE output.
%       Creates the directory if does not exist.
%       The name of the directory is different for each running matlab
%       process.
%
%   dname=tempmrcdir(key)
%       Append key (string) to the directory name. This enables to generate
%       two temporary directories for the same MATLAB process.
%
%   dname=tempmrcdir(key,tmpdir)
%       Use tmpdir as root for temporary ASPIRE files.

% Yoel Shkolnisky, January 2016


% Look for a configuration file defining the location of the temporary
% directory.

if ~exist('key','var')
    key=[];
else
    if ~ischar(key)
        error('key should be string');
    end
end

if ~exist('tmpdir','var')
    tmpdir='/scratch';
end

if isoctave()
    pid = getpid();
else
    pid=feature('getpid');
end

fname = mfilename('fullpath');
[pathstr,~,~] = fileparts(fname); % Find where the package installed.

% Try to read temprary directory from configuration file
ASIPRE_ROOT=fileparts(pathstr);
confname=fullfile(ASIPRE_ROOT,'tmpdir.cfg');

if exist(confname,'file')
    %log_message('Loading name for root of temporary folders from %s',confname);
    fid=fopen(confname,'r');
    tmpdir=fscanf(fid,'%s');
    fclose(fid);
else
    log_message('Configuration file %s not found',confname);
    log_message('Create file %s containing name of temporary folder to override default folder',confname)
    log_message('Using default folder ''/%s/'' as root of temporary folder',tmpdir);
end


uname=getenv('USER');
pidstr=int2str(pid);

dname=fullfile(filesep,tmpdir,uname,'aspire_temp',pidstr);
dname = '/data/amitayeldar/aspire_temp/1990925';
if ~isempty(key)
    dname=fullfile(dname,key);
end

if ~exist(dname,'dir')
    log_message('Creating temporary dir %s',dname);
    mkdir(dname);
end
