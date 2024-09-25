# Initialize an array to hold the final output
$finalResults = @()

# Process the fetched cluster data
foreach ($edge in $clusterData) {
    $node = $edge.node
    $activityConnection = $node.activityConnection.nodes

    # Gather all required fields into a hashtable
    $commonFields = @{
        ID                         = $node.id
        FID                        = $node.fid
        StartTime                  = $node.startTime
        ActivitySeriesId           = $node.activitySeriesId
        LastUpdated                = $node.lastUpdated
        LastActivityType           = $node.lastActivityType
        LastActivityStatus         = $node.lastActivityStatus
        ObjectId                   = $node.objectId
        ObjectName                 = $node.objectName
        ObjectType                 = $node.objectType
        Severity                   = $node.severity
        Progress                   = $node.progress
        IsCancelable               = $node.isCancelable
        IsPolarisEventSeries       = $node.isPolarisEventSeries
        Location                   = $node.location
        EffectiveThroughput        = $node.effectiveThroughput
        DataTransferred            = $node.dataTransferred
        LogicalSize                = $node.logicalSize
        ClusterUuid                = $node.clusterUuid
        ClusterName                = $node.clusterName
        Typename                   = $node.__typename
    }

    # Add activity connection details for each activity
    foreach ($activity in $activityConnection) {
        $finalResults += [PSCustomObject]@{
            ID                         = $commonFields.ID
            FID                        = $commonFields.FID
            StartTime                  = $commonFields.StartTime
            ActivitySeriesId           = $commonFields.ActivitySeriesId
            LastUpdated                = $commonFields.LastUpdated
            LastActivityType           = $commonFields.LastActivityType
            LastActivityStatus         = $commonFields.LastActivityStatus
            ObjectId                   = $commonFields.ObjectId
            ObjectName                 = $commonFields.ObjectName
            ObjectType                 = $commonFields.ObjectType
            Severity                   = $commonFields.Severity
            Progress                   = $commonFields.Progress
            IsCancelable               = $commonFields.IsCancelable
            IsPolarisEventSeries       = $commonFields.IsPolarisEventSeries
            Location                   = $commonFields.Location
            EffectiveThroughput        = $commonFields.EffectiveThroughput
            DataTransferred            = $commonFields.DataTransferred
            LogicalSize                = $commonFields.LogicalSize
            ClusterUuid                = $commonFields.ClusterUuid
            ClusterName                = $commonFields.ClusterName
            Typename                   = $commonFields.Typename
            ActivityID                 = $activity.id
            ActivityMessage            = $activity.message
        }
    }
}

# Export the final results to CSV
$outputFilePath = "/home/admin1/Desktop/GraphQL/backup_data.csv"
$finalResults | Export-Csv -Path $outputFilePath -NoTypeInformation

Write-Output "Data exported to $outputFilePath successfully."
