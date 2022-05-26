#convert_frequency_manager.ps1

# input format looks like this, with one MemoryEntry per entry
<# <?xml version="1.0"?>
<ArrayOfMemoryEntry xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <MemoryEntry>
    <IsFavourite>true</IsFavourite>
    <Name>Radio Metro</Name>
    <GroupName>Misc</GroupName>
    <Frequency>99500000</Frequency>
    <DetectorType>WFM</DetectorType>
    <Shift>0</Shift>
    <FilterBandwidth>250000</FilterBandwidth>
  </MemoryEntry>
  </ArrayOfMemoryEntry> #>

# intermediate class
class FrequencyEntry
{
    [string]$Name
    [string]$GroupName
    [int]$Frequency
    [int]$Bandwidth
    [string]$DetectorType
}

function GetMode([string]$modestring)
{
    <# const char* demodModeList[] = {
    "NFM",
    "WFM",
    "AM",
    "DSB",
    "USB",
    "CW",
    "LSB",
    "RAW"
}; #>
#echo $modestring
    [int]$retval = 0;
    switch($modestring)
    {
        "NFM" {$retval = 0}
        "WFM" {$retval = 1}
        "AM" {$retval = 2}
        "DSB" {$retval = 3}
        "USB" {$retval = 4}
        "CW" {$retval = 5}
        "LSB" {$retval = 6}
        "RAW" {$retval = 7}
    }
    return $retval;
}

$entries_xml = Select-Xml -Path .\frequencies.xml -XPath '/ArrayOfMemoryEntry/MemoryEntry'
#echo $entries
$entires_objects = New-Object System.Collections.ArrayList;
$groupnames = New-Object System.Collections.ArrayList;

foreach ($entry in $entries_xml) {
    $new_entry = [FrequencyEntry]::new();
    $new_entry.Name = $entry.Node.Name;
    $new_entry.GroupName = $entry.Node.GroupName;
    $new_entry.Frequency = $entry.Node.Frequency;
    $new_entry.Bandwidth = $entry.Node.FilterBandwidth;
    $new_entry.DetectorType = $entry.Node.DetectorType;
    [void]$entires_objects.Add($new_entry);

    if (!$groupnames.Contains($new_entry.GroupName))
    {
        $groupnames.Add($new_entry.GroupName);
    }
}

#output one file per source group
foreach ($group in $groupnames)
{
    $jsonBase = @{}
    $array = @{}
    foreach ($entry in $entires_objects)
    {
        #echo $group
        if ($entry.GroupName -ne $group)
        {
            continue;
        }
        $data = @{"bandwidth"=$entry.bandwidth;"frequency"=$entry.frequency;"mode"=GetMode($entry.DetectorType)}
        # XML file allows multiple with same name, but JSON doesn't
        if ($array.ContainsKey($entry.Name))
        {
            $i = 1;
            while ($array.ContainsKey($entry.Name + " (" + $i + ")"))
            {
                $i++;
            }
            $array.Add($entry.Name + " (" + $i + ")",$data)
        }
        else {
            $array.Add($entry.Name,$data)
        }
        
    }

    $jsonBase.Add("bookmarks",$array)
    $jsonBase | ConvertTo-Json -Depth 10 | Out-File (".\converted_" + $group + ".json")

}


# output looks like this for an import/export file
<# {"bookmarks":
    {"New Bookmark":
        {"bandwidth":12500.0,"frequency":1544475000.0,"mode":2}
    }
} #>