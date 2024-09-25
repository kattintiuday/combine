# Install the Import-Excel module if not already installed
# Install-Module -Name ImportExcel -Force -Scope CurrentUser

# Specify the path to your JSON file
$jsonFilePath = "C:\Users\UdayKumarKattinti\Desktop\Graphql\raw_cluster_data.json"

# Read the JSON data from the file
$jsonData = Get-Content -Path $jsonFilePath -Raw

# Convert the JSON string to a PowerShell object
$data = $jsonData | ConvertFrom-Json

# Prepare data for export in a columnar format
$exportData = @()

foreach ($item in $data) {
    # Create a base custom object for the current item with ActivityMessages initialized
    $customObject = [PSCustomObject]@{
        ID                  = $item.id
        FilesetName         = $item.objectName
        ObjectType          = $item.objectType
        StartTime           = $item.startTime
        LastActivityType    = $item.lastActivityType
        Status              = $item.lastActivityStatus
        Progress            = $item.progress
        Location            = $item.location
        ClusterName         = $item.clusterName
        ClusterStatus       = $item.cluster.status
        Timezone            = $item.cluster.timezone
        ActivityMessages    = "" # Initialize the property
    }

    # Collect activity messages
    $activityMessages = @()
    foreach ($activity in $item.activityConnection.nodes) {
        $activityMessages += $activity.message
    }

    # Join messages into a single string
    $customObject.ActivityMessages = [string]::Join(" | ", $activityMessages)

    # Add the custom object to the export data
    $exportData += $customObject
}

# Specify the output file path
$outputFile = "C:\Users\UdayKumarKattinti\Desktop\Graphql\ActivityReport.xlsx"

# Export to Excel with each property as a column
$exportData | Export-Excel -Path $outputFile -WorksheetName "Activity Series" -AutoSize
