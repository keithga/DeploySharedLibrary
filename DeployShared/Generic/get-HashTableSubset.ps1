

function get-HashTableSubset
{
<#
.SYNOPSIS
Return the subset of a HashTable
.DESCRIPTION
Great for Calling parent functions with the subset of arguments found in $PSBoundParameters
.EXAMPLE
$NewHash = get-HashTableSubset @PSBoundParameters -exclude Foo,Bar
Call-NewFunction @NewHash
#>
    [cmdletbinding()]
    param
    (
        [parameter(ValueFromPipeline=$True)] $HashTable,
        [string[]] $Include,
        [string[]] $Exclude
    )

    Begin { $Result = @{} }
    Process 
    {
        if ( $Include ) 
        {
            $HashTable.GetEnumerator() | where-object key -in $include | ForEach-Object {  $Result.add( $_.key, $_.value ) }
        }
        if ( $Exclude )
        {
            $HashTable.GetEnumerator() | where-object key -notin $exclude | ForEach-Object { $Result.add( $_.key, $_.value ) }
        }
        
    }
    End { return $Result }

}
