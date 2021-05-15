#Requires -version 6.0

param(
    [Parameter(Mandatory)][string] $maxNumber,
    [int] $maxIterations = 500
)

function Iterate-Number
{
    param(
        [string] $number
    )

    $numberArray = $number.ToCharArray() 
    $groupedArray = $numberArray | Group-Object

    return ($groupedArray | ForEach-Object {"$($_.count)$($_.name)"}) -join ""    
}

function Generate-Sequence
{
    param(
       [Parameter(Mandatory)][string] $number,
       [Parameter(Mandatory)][hashtable] $statemap,
       [Parameter(Mandatory)][int] $maxIterations
    )
    
    $history = @($number)
    foreach ($i in 1..$maxIterations)
    {
        # If the next iteration for this input has not been calculated so far this execution, 
        # calculate it and add it to the hashtable
        if (-not $statemap[$number]) 
        {
            $newNumber = Iterate-Number -number $number
            $statemap[$number] = $newNumber
        }
        # Otherwise retrieve the value from the hashtable
        else 
        {
            $newNumber = $statemap[$number]
        }
        
        # If the next iteration has appeared before so far this run, there is a cycle in the the sequence
        # so return
        if ($newNumber -in $history)
        {
            return $history
        }
        else
        {
            $history += $newNumber
        }

        # Set $number to $newnumber to reset for the next iteration
        $number = $newNumber
    }
    return $history
}

$sequences = @()
$statemap = @{}
$sequences += (1..$maxNumber) | ForEach-Object {
    $number = $_
    $sequence = Generate-Sequence -number $number -statemap $statemap -maxIterations $maxIterations
    return [PSCustomObject]@{
        Number = $number
        SequenceLength = $sequence.count
        Sequence = $sequence
    }
}

[void][Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms.DataVisualization")
$chartSavePath = 'C:\users\matti\Downloads'
 
# Creating chart object
# The System.Windows.Forms.DataVisualization.Charting namespace contains methods and properties for the Chart Windows forms control.
   $chartobject = New-object System.Windows.Forms.DataVisualization.Charting.Chart
   $chartobject.Width = 800
   $chartobject.Height =800
   $chartobject.BackColor = [System.Drawing.Color]::orange
 
# Set Chart title 
   [void]$chartobject.Titles.Add("dotnet-helpers chart-Sequence")
   $chartobject.Titles[0].Font = "Arial,13pt"
   $chartobject.Titles[0].Alignment = "topLeft"
 
# create a chartarea to draw on and add to chart
   $chartareaobject = New-Object System.Windows.Forms.DataVisualization.Charting.ChartArea
   $chartareaobject.Name = "ChartArea1"
   $chartareaobject.AxisY.Title = "dotnet-helpers chart - Sequence Length"
   $chartareaobject.AxisX.Title = "dotnet-helpers chart - Input Number"
   $chartareaobject.AxisY.Interval = 100
   $chartareaobject.AxisX.Interval = 1
   $chartobject.ChartAreas.Add($chartareaobject)
 
# Creating legend for the chart
   $legend = New-Object system.Windows.Forms.DataVisualization.Charting.Legend
   $legend.name = "Legend1"
   $chartobject.Legends.Add($legend)
 
# Get the top 5 process using in our system
   $topCPUUtilization = Get-Process | sort PrivateMemorySize -Descending  | Select-Object -First 5
 
# data series
   [void]$chartobject.Series.Add("SequenceLength")
   $chartobject.Series["SequenceLength"].ChartType = "Line"
   $chartobject.Series["SequenceLength"].BorderWidth  = 3
   $chartobject.Series["SequenceLength"].IsVisibleInLegend = $true
   $chartobject.Series["SequenceLength"].chartarea = "ChartArea1"
   $chartobject.Series["SequenceLength"].Legend = "Legend1"
   $chartobject.Series["SequenceLength"].color = "#00bfff"
   $sequences | ForEach-Object {$chartobject.Series["SequenceLength"].Points.addxy( $_.Number , $_.SequenceLength) }
 
# data series
   [void]$chartobject.Series.Add("PrivateMemory")
   $chartobject.Series["PrivateMemory"].ChartType = "Column"
   $chartobject.Series["PrivateMemory"].IsVisibleInLegend = $true
   $chartobject.Series["PrivateMemory"].BorderWidth  = 3
   $chartobject.Series["PrivateMemory"].chartarea = "ChartArea1"
   $chartobject.Series["PrivateMemory"].Legend = "Legend1"
   $chartobject.Series["PrivateMemory"].color = "#bf00ff"
   $topCPUUtilization | ForEach-Object {$chartobject.Series["PrivateMemory"].Points.addxy( $_.Name , ($_.PrivateMemorySize / 1000000)) }
 
# save chart with the Time frame for identifying the usage at the specific time
   $chartobject.SaveImage("$chartSavePath\CPUusage_$(get-date -format `"yyyyMMdd_hhmmsstt`").png","png")