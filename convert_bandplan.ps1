#convert_bandplan.ps1

# input format looks like this, with one MemoryEntry per entry
<# <ArrayOfRangeEntry xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <RangeEntry minFrequency="135700" maxFrequency="136000" color="50FF0000" mode="USB" step="10">2200m Ham Band|  Tests, Transatlantic Window </RangeEntry> #>

# intermediate class
class BandEntry
{
    [string]$Name
    [string]$Type
    <# broadcast, amateur, military, more? #>
    [Int64]$Start
    [Int64]$Stop
}

$entries_xml = Select-Xml -Path .\BandPlan.xml -XPath '/ArrayOfRangeEntry/RangeEntry'
#echo $entries
$entires_objects = New-Object System.Collections.ArrayList;

foreach ($entry in $entries_xml) {
    $new_entry = [BandEntry]::new();
    $new_entry.Name = $entry.Node.InnerText;
    $new_entry.Start= $entry.Node.minFrequency;
    $new_entry.Stop= $entry.Node.maxFrequency;

    # just guessing at these, would be better to support a colour field like SDR#?
    if ($entry.Node.InnerText.ToLower().Contains("ham") || $entry.Node.InnerText.ToLower().Contains("telegraphy"))
    {
        $new_entry.Type = "amateur";
    }
    elseif ($entry.Node.InnerText.ToLower().Contains("mil")) {
        $new_entry.Type = "military";
    }
    else {
        $new_entry.Type = "broadcast";
    }

    [void]$entires_objects.Add($new_entry);
    #echo $new_entry
}


$jsonBase = @{}
$array = @{}
$list = New-Object System.Collections.ArrayList

foreach ($entry in $entires_objects)
{
    [void]$list.Add(@{"name"=$entry.Name;"type"=$entry.Type;"start"=$entry.Start;"end"=$entry.Stop});
}
$jsonBase.Add("name","Imported")
$jsonBase.Add("country_name","Norway")
$jsonBase.Add("country_code","NO")
$jsonBase.Add("author_name","LA2YUA")
$jsonBase.Add("author_url","https://github.com/longview/SDRpp_Converters")

$jsonBase.Add("bands",$list)
$jsonBase | ConvertTo-Json -Depth 10 | Out-File ".\converted_bandplan.json"

# output looks like this for an import/export file
<# {"bookmarks":
    {"New Bookmark":
        {"bandwidth":12500.0,"frequency":1544475000.0,"mode":2}
    }
} #>