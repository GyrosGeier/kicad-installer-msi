@echo off

REM information

set output=kicad.msi

set product_name="KiCad nightly"
set product_manufacturer="The Kicad Community"
set product_version="0.0.0"
set product_code="{BFA000F2-107B-4002-BF83-538891C811A1}"
set upgrade_code="{CD9CEB98-6CB6-487D-9E43-DB4E096020E8}"

REM Generate package code
for /f %%i in ('uuidgen') do set package_code={%%i}

set package_code=%package_code:a=A%
set package_code=%package_code:b=B%
set package_code=%package_code:c=C%
set package_code=%package_code:d=D%
set package_code=%package_code:e=E%
set package_code=%package_code:f=F%

REM initialize

set _file_seq=0
set _cab_seq=0

REM cleanup

if exist msi rd /s /q msi
if exist files rd /s /q files

REM create MSI database

md msi
md files

call :init_makecab

call :create_validation_table
call :create_table Component
call :create_table Directory
call :create_table Feature
call :create_table FeatureComponents
call :create_table File
call :create_table InstallUISequence
call :create_table InstallExecuteSequence
call :create_table Media
call :create_table Property

rem call :add_property ErrorDialog ErrorDlg
call :add_property Manufacturer %product_manufacturer%
call :add_property ProductCode %product_code%
call :add_property ProductLanguage 1033
call :add_property ProductName %product_name%
call :add_property ProductVersion %product_version%
call :add_property UpgradeCode %upgrade_code%

call :setup_sequences

call :add_directory TARGETDIR "SourceDir"
call :add_directory ProgramFilesFolder "." "TARGETDIR"
call :add_directory kicad %product_name% "ProgramFilesFolder"
call :add_directory bin "bin" kicad

call :begin_feature main "Main"
call :add_component main bin
call :end_feature

call :copy_dlls

call :begin_cabinet x86
for %%f in (x86\_install\bin\*.exe)     do call :add_file "%%f" main
for %%f in (x86\_install\bin\*.kiface)  do call :add_file "%%f" main
for %%f in (x86\_install\bin\*.dll.*)   do call :add_file "%%f" main
call :end_cabinet

call :run_makecab
call :run_msidb

call :add_summary

exit /b

REM ============================================================================
REM add_summary
REM ============================================================================
:add_summary

msiinfo %output% -c 1252
msiinfo %output% -t "Installation Database"
msiinfo %output% -j %product_name%
msiinfo %output% -a %product_manufacturer%
msiinfo %output% -k Installer
msiinfo %output% -o "This installer database contains the logic and data required to install %product_name:"=%."
msiinfo %output% -p Intel;1033
msiinfo %output% -v %package_code%
rem msiinfo %output% -r
rem msiinfo %output% -q
msiinfo %output% -g 405
msiinfo %output% -w 2
msiinfo %output% -u 2

exit /b

REM ============================================================================
REM copy_dlls
REM ============================================================================
:copy_dlls

copy /b /y x86\dll\* x86\_install\bin\

exit /b

REM ============================================================================
REM create_validation_table
REM ============================================================================
:create_validation_table

(echo.Table	Column	Nullable	MinValue	MaxValue	KeyTable	KeyColumn	Category	Set	Description) > msi\_Validation.idt
(echo.s32	s32	s4	I4	I4	S255	I2	S32	S255	S255) >> msi\_Validation.idt
(echo._Validation	Table	Column) >> msi\_Validation.idt
(echo._Validation	Category	Y						Text;Formatted;Template;Condition;Guid;Path;Version;Language;Identifier;Binary;UpperCase;LowerCase;Filename;Paths;AnyPath;WildCardFilename;RegPath;KeyFormatted;CustomSource;Property;Cabinet;Shortcut;URL	String category) >> msi\_Validation.idt
(echo._Validation	Column	N					Identifier		Name of column) >> msi\_Validation.idt
(echo._Validation	Description	Y					Text		Description of column) >> msi\_Validation.idt
(echo._Validation	KeyColumn	Y	1	32					Column to which foreign key connects) >> msi\_Validation.idt
(echo._Validation	KeyTable	Y					Identifier		For foreign key, Name of table to which data must link) >> msi\_Validation.idt
(echo._Validation	MaxValue	Y	-2147483647	2147483647					Maximum value allowed) >> msi\_Validation.idt
(echo._Validation	MinValue	Y	-2147483647	2147483647					Minimum value allowed) >> msi\_Validation.idt
(echo._Validation	Nullable	N						Y;N	Whether the column is nullable) >> msi\_Validation.idt
(echo._Validation	Set	Y					Text		Set of values that are permitted) >> msi\_Validation.idt
(echo._Validation	Table	N					Identifier		Name of table) >> msi\_Validation.idt

exit /b

REM ============================================================================
REM create_table <name>
REM ============================================================================
:create_table

call :create_table_%1

exit /b

:create_table_Component

(echo.Component	ComponentId	Directory_	Attributes	Condition	KeyPath) > msi\Component.idt
(echo.s72	S38	s72	i2	S255	S72) >> msi\Component.idt
(echo.Component	Component) >> msi\Component.idt

(echo.Component	Attributes	N							Remote execution option, one of irsEnum) >> msi\_Validation.idt
(echo.Component	Component	N					Identifier		Primary key used to identify a particular component record.) >> msi\_Validation.idt
(echo.Component	ComponentId	Y					Guid		A string GUID unique to this component, version, and language.) >> msi\_Validation.idt
(echo.Component	Condition	Y					Condition		A conditional statement that will disable this component if the specified condition evaluates to the 'True' state. If a component is disabled, it will not be installed, regardless of the 'Action' state associated with the component.) >> msi\_Validation.idt
(echo.Component	Directory_	N			Directory	1	Identifier		Required key of a Directory table record. This is actually a property name whose value contains the actual path, set either by the AppSearch action or with the default setting obtained from the Directory table.) >> msi\_Validation.idt
(echo.Component	KeyPath	Y			File;Registry;ODBCDataSource	1	Identifier		Either the primary key into the File table, Registry table, or ODBCDataSource table. This extract path is stored when the component is installed, and is used to detect the presence of the component and to return the path to it.) >> msi\_Validation.idt

exit /b

:create_table_Directory

(echo.Directory	Directory_Parent	DefaultDir) > msi\Directory.idt
(echo.s72	S72	l255) >> msi\Directory.idt
(echo.Directory	Directory) >> msi\Directory.idt

(echo.Directory	DefaultDir	N					DefaultDir		The default sub-path under parent's path.) >> msi\_Validation.idt
(echo.Directory	Directory	N					Identifier		Unique identifier for directory entry, primary key. If a property by this name is defined, it contains the full path to the directory.) >> msi\_Validation.idt
(echo.Directory	Directory_Parent	Y			Directory	1	Identifier		Reference to the entry in this table specifying the default parent directory. A record parented to itself or with a Null parent represents a root of the install tree.) >> msi\_Validation.idt

exit /b

:create_table_Feature

(echo.Feature	Feature_Parent	Title	Description	Display	Level	Directory_	Attributes) > msi\Feature.idt
(echo.s38	S38	L64	L255	I2	i2	S72	i2) >> msi\Feature.idt
(echo.Feature	Feature) >> msi\Feature.idt

(echo.Feature	Attributes	N						0;1;2;4;5;6;8;9;10;16;17;18;20;21;22;24;25;26;32;33;34;36;37;38;48;49;50;52;53;54	Feature attributes) >> msi\_Validation.idt
(echo.Feature	Description	Y					Text		Longer descriptive text describing a visible feature item.) >> msi\_Validation.idt
(echo.Feature	Directory_	Y			Directory	1	UpperCase		The name of the Directory that can be configured by the UI. A non-null value will enable the browse button.) >> msi\_Validation.idt
(echo.Feature	Display	Y	0	32767					Numeric sort order, used to force a specific display ordering.) >> msi\_Validation.idt
(echo.Feature	Feature	N					Identifier		Primary key used to identify a particular feature record.) >> msi\_Validation.idt
(echo.Feature	Feature_Parent	Y			Feature	1	Identifier		Optional key of a parent record in the same table. If the parent is not selected, then the record will not be installed. Null indicates a root item.) >> msi\_Validation.idt
(echo.Feature	Level	N	0	32767					The install level at which record will be initially selected. An install level of 0 will disable an item and prevent its display.) >> msi\_Validation.idt
(echo.Feature	Title	Y					Text		Short text identifying a visible feature item.) >> msi\_Validation.idt

exit /b

:create_table_FeatureComponents

(echo.Feature_	Component_) > msi\FeatureComponents.idt
(echo.s38	s72) >> msi\FeatureComponents.idt
(echo.FeatureComponents	Feature_	Component_) >> msi\FeatureComponents.idt

(echo.FeatureComponents	Component_	N			Component	1	Identifier		Foreign key into Component table.) >> msi\_Validation.idt
(echo.FeatureComponents	Feature_	N			Feature	1	Identifier		Foreign key into Feature table.) >> msi\_Validation.idt

exit /b

:create_table_File

(echo.File	Component_	FileName	FileSize	Version	Language	Attributes	Sequence) > msi\File.idt
(echo.s72	s72	l255	i4	S72	S20	I2	i2) >> msi\File.idt
(echo.File	File) >> msi\File.idt

(echo.File	Attributes	Y	0	32767					Integer containing bit flags representing file attributes ^(with the decimal value of each bit position in parentheses^)) >> msi\_Validation.idt
(echo.File	Component_	N			Component	1	Identifier		Foreign key referencing Component that controls the file.) >> msi\_Validation.idt
(echo.File	File	N					Identifier		Primary key, non-localized token, must match identifier in cabinet.  For uncompressed files, this field is ignored.) >> msi\_Validation.idt
(echo.File	FileName	N					Filename		File name used for installation, may be localized.  This may contain a "short name|long name" pair.) >> msi\_Validation.idt
(echo.File	FileSize	N	0	2147483647					Size of file in bytes ^(long integer^).) >> msi\_Validation.idt
(echo.File	Language	Y					Language		List of decimal language Ids, comma-separated if more than one.) >> msi\_Validation.idt
(echo.File	Sequence	N	1	32767					Sequence with respect to the media images; order must track cabinet order.) >> msi\_Validation.idt
(echo.File	Version	Y			File	1	Version		Version string for versioned files;  Blank for unversioned files.) >> msi\_Validation.idt

exit /b

:create_table_InstallUISequence

(echo.Action	Condition	Sequence) > msi\InstallUISequence.idt
(echo.s72	S255	I2) >> msi\InstallUISequence.idt
(echo.InstallUISequence	Action) >> msi\InstallUISequence.idt

(echo.InstallUISequence	Action	N					Identifier		Name of action to invoke, either in the engine or the handler DLL.) >> msi\_Validation.idt
(echo.InstallUISequence	Condition	Y					Condition		Optional expression which skips the action if evaluates to expFalse.If the expression syntax is invalid, the engine will terminate, returning iesBadActionData.) >> msi\_Validation.idt
(echo.InstallUISequence	Sequence	Y	-4	32767					Number that determines the sort order in which the actions are to be executed.  Leave blank to suppress action.) >> msi\_Validation.idt

exit /b

:create_table_InstallExecuteSequence

(echo.Action	Condition	Sequence) > msi\InstallExecuteSequence.idt
(echo.s72	S255	I2) >> msi\InstallExecuteSequence.idt
(echo.InstallExecuteSequence	Action) >> msi\InstallExecuteSequence.idt

(echo.InstallExecuteSequence	Action	N					Identifier		Name of action to invoke, either in the engine or the handler DLL.) >> msi\_Validation.idt
(echo.InstallExecuteSequence	Condition	Y					Condition		Optional expression which skips the action if evaluates to expFalse.If the expression syntax is invalid, the engine will terminate, returning iesBadActionData.) >> msi\_Validation.idt
(echo.InstallExecuteSequence	Sequence	Y	-4	32767					Number that determines the sort order in which the actions are to be executed.  Leave blank to suppress action.) >> msi\_Validation.idt

exit /b

:create_table_Media

(echo.DiskId	LastSequence	DiskPrompt	Cabinet	VolumeLabel	Source) > msi\Media.idt
(echo.i2	i2	L64	S255	S32	S72) >> msi\Media.idt
(echo.Media	DiskId) >> msi\Media.idt

(echo.Media	Cabinet	Y					Cabinet		If some or all of the files stored on the media are compressed in a cabinet, the name of that cabinet.) >> msi\_Validation.idt
(echo.Media	DiskId	N	1	32767					Primary key, integer to determine sort order for table.) >> msi\_Validation.idt
(echo.Media	DiskPrompt	Y					Text		Disk name: the visible text actually printed on the disk.  This will be used to prompt the user when this disk needs to be inserted.) >> msi\_Validation.idt
(echo.Media	LastSequence	N	0	32767					File sequence number for the last file for this media.) >> msi\_Validation.idt
(echo.Media	Source	Y					Property		The property defining the location of the cabinet file.) >> msi\_Validation.idt
(echo.Media	VolumeLabel	Y					Text		The label attributed to the volume.) >> msi\_Validation.idt

exit /b

:create_table_Property

(echo.Property	Value) > msi\Property.idt
(echo.s72	l0) >> msi\Property.idt
(echo.Property	Property) >> msi\Property.idt

(echo.Property	Property	N					Identifier		Name of property, uppercase if settable by launcher or loader.) >> msi\_Validation.idt
(echo.Property	Value	N					Text		String value for property.  Never null or empty.) >> msi\_Validation.idt

exit /b

REM ============================================================================
REM init_makecab
REM ============================================================================
:init_makecab
echo..set Cabinet=on >makecab.txt
echo..set DiskDirectoryTemplate= >>makecab.txt
echo..set Compress=on >>makecab.txt
echo..set GenerateInf=on >>makecab.txt
echo..set UniqueFiles=off >>makecab.txt
echo..set MaxDiskSize=0 >>makecab.txt
echo. >>makecab.txt

exit /b

REM ============================================================================
REM run_makecab
REM ============================================================================
:run_makecab
makecab /f makecab.txt

exit /b

REM ============================================================================
REM run_msidb
REM ============================================================================
:run_msidb
if exist %output% del %output%
msidb -d %output% -f %CD%\msi -c *
msidb -d %output% -a x86.cab

exit /b

REM ============================================================================
REM begin_cabinet <name>
REM ============================================================================
:begin_cabinet
set /a _cab_seq=%_cab_seq%+1
set _cab_name=%1.cab
(echo..set CabinetName%_cab_seq%=%_cab_name%) >>makecab.txt
(echo..new Cabinet) >>makecab.txt

exit /b

REM ============================================================================
REM end_cabinet
REM ============================================================================
:end_cabinet
(echo.%_cab_seq%	%_file_seq%		#%_cab_name%		) >>msi\Media.idt

exit /b

REM ============================================================================
REM add_property <name> <value>
REM ============================================================================
:add_property
(echo.%1	%~2) >>msi\Property.idt

exit /b

REM ============================================================================
REM add_directory <name> <dir> <parent>
REM ============================================================================
:add_directory

(echo.%1	%~3	%~2) >>msi\Directory.idt

exit /b

REM ============================================================================
REM begin_feature <name> <title>
REM ============================================================================
:begin_feature

set _feat_name=%1

(echo.%1		%~2		1	1		0) >>msi\Feature.idt

exit /b

REM ============================================================================
REM end_feature
REM ============================================================================
:end_feature
exit /b

REM ============================================================================
REM add_component <name> <dir>
REM ============================================================================
:add_component
(echo.%1		%~2	0		) >>msi\Component.idt
(echo.%_feat_name%	%1) >>msi\FeatureComponents.idt

exit /b

REM ============================================================================
REM add_file <src> <component>
REM ============================================================================
:add_file

set /a _file_seq=%_file_seq%+1

set _file_id=%~1
set _file_id=%_file_id:\_install=%
set _file_id=%_file_id:\=_%
set _file_id=%_file_id:-=_%

copy "%1" files\%_file_id%

if %~nx1==%~snx1 (set _file_name="%~nx1") else (set _file_name="%~snx1^|%~nx1")

(echo.%_file_id%	%2	%_file_name:"=%	%~z1			512	%_file_seq%) >> msi\File.idt
(echo.files\%_file_id%) >>makecab.txt

exit /b

REM ============================================================================
REM setup_sequences
REM ============================================================================
:setup_sequences

(echo.LaunchConditions		100) >> msi\InstallUISequence.idt
(echo.AppSearch		400) >> msi\InstallUISequence.idt
(echo.CCPSearch	NOT Installed	500) >> msi\InstallUISequence.idt
(echo.RMCCPSearch	NOT Installed	600) >> msi\InstallUISequence.idt
(echo.CostInitialize		800) >> msi\InstallUISequence.idt
(echo.FileCost		900) >> msi\InstallUISequence.idt
(echo.CostFinalize		1000) >> msi\InstallUISequence.idt
(echo.ExecuteAction		1300) >> msi\InstallUISequence.idt

(echo.LaunchConditions		100) >> msi\InstallExecuteSequence.idt
(echo.AppSearch		400) >> msi\InstallExecuteSequence.idt
(echo.CCPSearch	NOT Installed	500) >> msi\InstallExecuteSequence.idt
(echo.RMCCPSearch	NOT Installed	600) >> msi\InstallExecuteSequence.idt
(echo.ValidateProductID		700) >> msi\InstallExecuteSequence.idt
(echo.CostInitialize		800) >> msi\InstallExecuteSequence.idt
(echo.FileCost		900) >> msi\InstallExecuteSequence.idt
(echo.CostFinalize		1000) >> msi\InstallExecuteSequence.idt
(echo.SetODBCFolders		1100) >> msi\InstallExecuteSequence.idt
(echo.InstallValidate		1400) >> msi\InstallExecuteSequence.idt
(echo.InstallInitialize		1500) >> msi\InstallExecuteSequence.idt
(echo.AllocateRegistrySpace	NOT Installed	1550) >> msi\InstallExecuteSequence.idt
(echo.ProcessComponents		1600) >> msi\InstallExecuteSequence.idt
(echo.UnpublishComponents		1700) >> msi\InstallExecuteSequence.idt
(echo.UnpublishFeatures		1800) >> msi\InstallExecuteSequence.idt
(echo.StopServices	VersionNT	1900) >> msi\InstallExecuteSequence.idt
(echo.DeleteServices	VersionNT	2000) >> msi\InstallExecuteSequence.idt
(echo.UnregisterComPlus		2100) >> msi\InstallExecuteSequence.idt
(echo.SelfUnregModules		2200) >> msi\InstallExecuteSequence.idt
(echo.UnregisterTypeLibraries		2300) >> msi\InstallExecuteSequence.idt
(echo.RemoveODBC		2400) >> msi\InstallExecuteSequence.idt
(echo.UnregisterFonts		2500) >> msi\InstallExecuteSequence.idt
(echo.RemoveRegistryValues		2600) >> msi\InstallExecuteSequence.idt
(echo.UnregisterClassInfo		2700) >> msi\InstallExecuteSequence.idt
(echo.UnregisterExtensionInfo		2800) >> msi\InstallExecuteSequence.idt
(echo.UnregisterProgIdInfo		2900) >> msi\InstallExecuteSequence.idt
(echo.UnregisterMIMEInfo		3000) >> msi\InstallExecuteSequence.idt
(echo.RemoveIniValues		3100) >> msi\InstallExecuteSequence.idt
(echo.RemoveShortcuts		3200) >> msi\InstallExecuteSequence.idt
(echo.RemoveEnvironmentStrings		3300) >> msi\InstallExecuteSequence.idt
(echo.RemoveDuplicateFiles		3400) >> msi\InstallExecuteSequence.idt
(echo.RemoveFiles		3500) >> msi\InstallExecuteSequence.idt
(echo.RemoveFolders		3600) >> msi\InstallExecuteSequence.idt
(echo.CreateFolders		3700) >> msi\InstallExecuteSequence.idt
(echo.MoveFiles		3800) >> msi\InstallExecuteSequence.idt
(echo.InstallFiles		4000) >> msi\InstallExecuteSequence.idt
(echo.PatchFiles		4090) >> msi\InstallExecuteSequence.idt
(echo.DuplicateFiles		4210) >> msi\InstallExecuteSequence.idt
(echo.BindImage		4300) >> msi\InstallExecuteSequence.idt
(echo.CreateShortcuts		4500) >> msi\InstallExecuteSequence.idt
(echo.RegisterClassInfo		4600) >> msi\InstallExecuteSequence.idt
(echo.RegisterExtensionInfo		4700) >> msi\InstallExecuteSequence.idt
(echo.RegisterProgIdInfo		4800) >> msi\InstallExecuteSequence.idt
(echo.RegisterMIMEInfo		4900) >> msi\InstallExecuteSequence.idt
(echo.WriteRegistryValues		5000) >> msi\InstallExecuteSequence.idt
(echo.WriteIniValues		5100) >> msi\InstallExecuteSequence.idt
(echo.WriteEnvironmentStrings		5200) >> msi\InstallExecuteSequence.idt
(echo.RegisterFonts		5300) >> msi\InstallExecuteSequence.idt
(echo.InstallODBC		5400) >> msi\InstallExecuteSequence.idt
(echo.RegisterTypeLibraries		5500) >> msi\InstallExecuteSequence.idt
(echo.SelfRegModules		5600) >> msi\InstallExecuteSequence.idt
(echo.RegisterComPlus		5700) >> msi\InstallExecuteSequence.idt
(echo.InstallServices	VersionNT	5800) >> msi\InstallExecuteSequence.idt
(echo.StartServices	VersionNT	5900) >> msi\InstallExecuteSequence.idt
(echo.RegisterUser		6000) >> msi\InstallExecuteSequence.idt
(echo.RegisterProduct		6100) >> msi\InstallExecuteSequence.idt
(echo.PublishComponents		6200) >> msi\InstallExecuteSequence.idt
(echo.PublishFeatures		6300) >> msi\InstallExecuteSequence.idt
(echo.PublishProduct		6400) >> msi\InstallExecuteSequence.idt
(echo.InstallFinalize		6600) >> msi\InstallExecuteSequence.idt

exit /b
