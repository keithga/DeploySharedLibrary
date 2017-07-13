<#

Pester tests for unattend.xml files

#>

. $PSScriptRoot\New-Unattend.ps1


#######################################
function get-OuterXML ( [parameter(Mandatory=$true,ValueFromPipeline=$true)] [System.Xml.XmlDocument] $XML )
{
    $XML.DocumentElement.OuterXML | Write-Output
}

#######################################

$StandardComponentAttributes = 'publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"'

function ControlXML
{
 @"
<unattend xmlns="urn:schemas-microsoft-com:unattend">
    <settings pass="generalize">
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" $StandardComponentAttributes>
            <DoNotCleanTaskBar>true</DoNotCleanTaskBar>
        </component>
    </settings>
    <settings pass="specialize">
        <component name="Microsoft-Windows-Deployment" processorArchitecture="amd64" $StandardComponentAttributes>
            <RunSynchronous>
                <RunSynchronousCommand wcm:action="add">
                    <Description>EnableAdmin</Description>
                    <Order>1</Order>
                    <Path>cmd /c net user Administrator /active:yes</Path>
                </RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add">
                    <Description>UnfilterAdministratorToken</Description>
                    <Order>2</Order>
                    <Path>cmd /c reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /v FilterAdministratorToken /t REG_DWORD /d 0 /f</Path>
                </RunSynchronousCommand>
            </RunSynchronous>
        </component>
        <component name="Microsoft-Windows-International-Core" processorArchitecture="amd64" $StandardComponentAttributes>
            <InputLocale>0409:00000409</InputLocale>
            <SystemLocale>en-US</SystemLocale>
            <UILanguage>en-US</UILanguage>
            <UserLocale>en-US</UserLocale>
        </component>
    </settings>
    <settings pass="offlineServicing">
        <component name="Microsoft-Windows-PnpCustomizationsNonWinPE" processorArchitecture="amd64" $StandardComponentAttributes>
            <DriverPaths>
                <PathAndCredentials wcm:keyValue="1" wcm:action="add">
                    <Path>\Drivers</Path>
                </PathAndCredentials>
            </DriverPaths>
        </component>
    </settings>
</unattend>
"@  -as [xml] | Write-Output

}



Describe "UNATTEND Tests" {

    it "Empty Case"  {
        UNATTEND {} | get-OuterXML | should be '<unattend xmlns="urn:schemas-microsoft-com:unattend" />'
    }

    it "PassThru" {
        ControlXML | UNATTEND {} | get-OuterXML | should be (ControlXML).DocumentElement.OuterXml
    }

    it "Arg1" {
        UNATTEND -XML (ControlXML) {} | get-OuterXML | should be (ControlXML).DocumentElement.OuterXml
    }

}

Describe "SETTINGS Tests" {

    $SettingsX = @( "auditSystem","auditUser","generalize","offlineServicing","oobeSystem","specialize","windowsPE" )

    foreach ( $SettingX in $SettingsX ) 
    {
        it "testing $SettingX" {

            UNATTEND { SETTINGS -Pass $SettingX {} } | get-OuterXML | 
                should be "<unattend xmlns=""urn:schemas-microsoft-com:unattend""><settings pass=""$SettingX"" /></unattend>"

        }
    }

    it "testing generalize" {
        { UNATTEND { SETTINGS -Pass "generalize" {} } } | should not throw
    }

    it "testing Unknown" {
        { UNATTEND { SETTINGS -Pass "unknown" {} } } | should throw
    }

    it "testing missing" {
        { UNATTEND { SETTINGS -Pass "" {} } } | should throw
    }

    it "testing existing" {
        ControlXML | UNATTEND { SETTINGS -Pass "generalize" {} } | get-OuterXML | should be (ControlXML).DocumentElement.OuterXml
    }

    it "testing existing" {
        ControlXML | UNATTEND { SETTINGS -Pass "specialize" {} } | get-OuterXML | should be (ControlXML).DocumentElement.OuterXml
    }

    it "testing existing" { 
        ControlXML | UNATTEND { SETTINGS -Pass "oobesystem" {} } | get-OuterXML | 
            should be (ControlXML).DocumentElement.OuterXml.replace("</unattend>","<settings pass=""oobeSystem"" /></unattend>")
    }

}

describe "Component tests" {

    it "testing components" {
        
         UNATTEND { SETTINGS -Pass "generalize" { COMPONENT "X" {} } } | get-OuterXML | 
            should be "<unattend xmlns=""urn:schemas-microsoft-com:unattend""><settings pass=""generalize""><component name=""X"" processorArchitecture=""amd64"" $StandardComponentAttributes /></settings></unattend>"

         UNATTEND { SETTINGS -Pass "generalize" { COMPONENT "X" -Architecture amd64 {} } } | get-OuterXML | 
            should be "<unattend xmlns=""urn:schemas-microsoft-com:unattend""><settings pass=""generalize""><component name=""X"" processorArchitecture=""amd64"" $StandardComponentAttributes /></settings></unattend>"

         UNATTEND { SETTINGS -Pass "generalize" { COMPONENT "X" -Architecture x86 {} } } | get-OuterXML | 
            should be "<unattend xmlns=""urn:schemas-microsoft-com:unattend""><settings pass=""generalize""><component name=""X"" processorArchitecture=""x86"" $StandardComponentAttributes /></settings></unattend>"

    }

    it "testing existing" { 
        ControlXML | UNATTEND { SETTINGS -Pass "oobesystem" {  COMPONENT "X" {} } } | get-OuterXML | 
            should be (COntrolXML).DocumentElement.OuterXml.replace("</unattend>","<settings pass=""oobesystem""><component name=""X"" processorArchitecture=""amd64"" $StandardComponentAttributes /></settings></unattend>")
    }

    it "testing existing x64" { 
        ControlXML | UNATTEND { SETTINGS -Pass "oobesystem" {  COMPONENT "X" -Architecture amd64 {} } } | get-OuterXML | 
            should be (COntrolXML).DocumentElement.OuterXml.replace("</unattend>","<settings pass=""oobesystem""><component name=""X"" processorArchitecture=""amd64"" $StandardComponentAttributes /></settings></unattend>")
    }

    it "testing existing x86" { 
        ControlXML | UNATTEND { SETTINGS -Pass "oobesystem" {  COMPONENT "X" -Architecture x86 {} } } | get-OuterXML | 
            should be (COntrolXML).DocumentElement.OuterXml.replace("</unattend>","<settings pass=""oobesystem""><component name=""X"" processorArchitecture=""x86"" $StandardComponentAttributes /></settings></unattend>")
    }

}

describe "Element tests" {

    Function Get-TestString( $Test ) 
    { 
        "<unattend xmlns=""urn:schemas-microsoft-com:unattend""><settings pass=""generalize"">" + 
        "<component name=""Test0"" processorArchitecture=""amd64"" $StandardComponentAttributes>$test</component></settings></unattend>" | Write-Output
    } 

    it "testing element" { 
        UNATTEND { SETTINGS generalize { COMPONENT Test0 {
            ELEMENT Test1 Test2
        }}} | get-OuterXML | 
            should be (Get-TestString "<Test1>Test2</Test1>") 
    } 

    it "testing element with dangerous charcters" { 
        UNATTEND { SETTINGS generalize { COMPONENT Test0 {
            ELEMENT Test1 "<test>"
        }}} | get-OuterXML | 
            should be (Get-TestString "<Test1>&lt;test&gt;</Test1>") 
    } 

    it "testing element within element" { 
        UNATTEND { SETTINGS generalize { COMPONENT Test0 {
            ELEMENT Test1 { ELEMENT Test2 TEst3 }
        }}} | get-OuterXML | 
            should be (Get-TestString "<Test1><Test2>TEst3</Test2></Test1>") 
    } 

    it "testing element within  element (2nd overwrite)" { 
        UNATTEND { SETTINGS generalize { COMPONENT Test0 {
            ELEMENT Test1 Test2
            ELEMENT Test1 Test3
        }}} | get-OuterXML | 
            should be (Get-TestString "<Test1>Test3</Test1>") 
    } 

    it "testing element within element (force new)" { 
        UNATTEND { SETTINGS generalize { COMPONENT Test0 {
            ELEMENT Test1 Test2
            ELEMENT Test1 Test3 -ForceNew
        }}} | get-OuterXML | 
            should be (Get-TestString "<Test1>Test2</Test1><Test1>Test3</Test1>") 
    } 

    it "testing element within element with attributes" { 
        UNATTEND { SETTINGS generalize { COMPONENT Test0 {
            ELEMENT Test1 Test2 -Attributes "cat=dog"
        }}} | get-OuterXML | 
            should be (Get-TestString "<Test1 cat=""dog"">Test2</Test1>") 
    } 

    it "testing element within element with attributes" { 
        UNATTEND { SETTINGS generalize { COMPONENT Test0 {
            ELEMENT Test1 Test2 -TypeAdd
        }}} | get-OuterXML | 
            should be (Get-TestString "<Test1 wcm:action=""add"">Test2</Test1>") 
    } 

    it "testing element within element with xpath" { 
        UNATTEND { SETTINGS generalize { COMPONENT Test0 {
            ELEMENT Test1 Test2
            ELEMENT Test1 Test3 -ForceNew
            ElEMENT Test1 Test4 -XPath "urn:Test1"
        }}} | get-OuterXML | 
            should be (Get-TestString "<Test1>Test4</Test1><Test1>Test3</Test1>") 
    } 

    it "testing element within element with xpath target to item" { 
        UNATTEND { SETTINGS generalize { COMPONENT Test0 {
            ELEMENT Test1 Test2
            ELEMENT Test1 Test3 -ForceNew
            ElEMENT Test1 Test4 -XPath "urn:Test1[. = ""Test3""]"
        }}} | get-OuterXML | 
            should be (Get-TestString "<Test1>Test2</Test1><Test1>Test4</Test1>") 
    } 

    it "testing element within element with xpath target to item" { 
        UNATTEND { SETTINGS generalize { COMPONENT Test0 {
            ELEMENT Test1 Test2
            ELEMENT Test1 { ELEMENT Test3 Test5 } -ForceNew
            ElEMENT Test1 Test4 -XPath "urn:Test1[urn:Test3]"
        }}} | get-OuterXML | 
            should be (Get-TestString "<Test1>Test2</Test1><Test1>Test4</Test1>") 
    } 

    it "testing element within element with xpath target to item" { 
        UNATTEND { SETTINGS generalize { COMPONENT Test0 {
            ELEMENT Test1 Test2
            ELEMENT Test1 { ELEMENT Test3 Test5 } -ForceNew
            ElEMENT Test1 { ELEMENT Test3 Test4 } -XPath "urn:Test1[urn:Test3]"
        }}} | get-OuterXML | 
            should be (Get-TestString "<Test1>Test2</Test1><Test1><Test3>Test4</Test3></Test1>") 
    } 

}

describe "Password tests" {

    Function Get-TestString( $Test ) 
    { 
        "<unattend xmlns=""urn:schemas-microsoft-com:unattend""><settings pass=""generalize"">" + 
        "<component name=""Test0"" processorArchitecture=""amd64"" $StandardComponentAttributes>$test</component></settings></unattend>" | Write-Output
    } 

    it "password in plain text" { 
        UNATTEND { SETTINGS generalize { COMPONENT Test0 {
            ELEMENT Test1 {
                PASSWORD "Password" "P@ssw0rd" -PlainText $True
            }
        }}} | get-OuterXML | 
            should be (Get-TestString "<Test1><Password><Value>P@ssw0rd</Value><PlainText>true</PlainText></Password></Test1>") 
    } 

    it "password in encoded form" { 
        UNATTEND { SETTINGS generalize { COMPONENT Test0 {
            ELEMENT Test1 {
                PASSWORD "Password" "P@ssw0rd"
            }
        }}} | get-OuterXML | 
            should be (Get-TestString "<Test1><Password><Value>UABAAHMAcwB3ADAAcgBkAFAAYQBzAHMAdwBvAHIAZAA=</Value><PlainText>false</PlainText></Password></Test1>") 
    } 

}

describe "full test" {

    it "testing the whole enchilada (From scratch)" {

        UNATTEND  {
            SETTINGS generalize  {
                COMPONENT Microsoft-Windows-Shell-Setup {
                    ELEMENT DoNotCleanTaskBar $True.ToString().ToLower()
                }
            }
            SETTINGS specialize  {
                COMPONENT Microsoft-Windows-Deployment {
                    ELEMENT RunSynchronous {
                        ELEMENT RunSynchronousCommand -TypeAdd {
                            ELEMENT Description "EnableAdmin"
                            ELEMENT Order "1"
                            ELEMENT Path "cmd /c net user Administrator /active:yes" 
                        }
                        ELEMENT RunSynchronousCommand -TypeAdd -ForceNew  {
                            ELEMENT Description "UnfilterAdministratorToken"
                            ELEMENT Order "2" 
                            ELEMENT Path "cmd /c reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /v FilterAdministratorToken /t REG_DWORD /d 0 /f" 
                        }
                    }
                }
                COMPONENT Microsoft-Windows-International-Core {
                    ELEMENT InputLocale '0409:00000409' 
                    ELEMENT SystemLocale 'en-US'
                    ELEMENT UILanguage 'en-US'
                    ELEMENT UserLocale 'en-US'
                }
            }
            SETTINGS offlineServicing  {
                COMPONENT Microsoft-Windows-PnpCustomizationsNonWinPE {
                    ELEMENT DriverPaths {
                        ELEMENT PathAndCredentials -Attributes 'keyValue=1' -TypeAdd {
                            ELEMENT Path '\Drivers'
                        }
                    }
                }
            }
        }  | get-OuterXML | should be (COntrolXML).DocumentElement.OuterXml

    }

    it "testing the whole enchilada (From template)" {

        COntrolXML | UNATTEND  {
            SETTINGS generalize  {
                COMPONENT Microsoft-Windows-Shell-Setup {
                    ELEMENT DoNotCleanTaskBar $True.ToString().ToLower()
                }
            }
            SETTINGS specialize  {
                COMPONENT Microsoft-Windows-Deployment {
                    ELEMENT RunSynchronous {
                        $Command = "cmd /c net user Administrator /active:yes"
                        ELEMENT RunSynchronousCommand -TypeAdd -xpath "urn:RunSynchronousCommand[urn:Path = ""$Command""]"  {
                            ELEMENT Description "EnableAdmin"
                            ELEMENT Order "1"
                            ELEMENT Path $Command
                        }
                        $Command = "cmd /c reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /v FilterAdministratorToken /t REG_DWORD /d 0 /f"
                        ELEMENT RunSynchronousCommand -TypeAdd -xpath "urn:RunSynchronousCommand[urn:Path = ""$Command""]"  {
                            ELEMENT Description "UnfilterAdministratorToken"
                            ELEMENT Order "2"
                            ELEMENT Path $Command
                        }
                    }
                }
                COMPONENT Microsoft-Windows-International-Core {
                    ELEMENT InputLocale '0409:00000409' 
                    ELEMENT SystemLocale 'en-US'
                    ELEMENT UILanguage 'en-US'
                    ELEMENT UserLocale 'en-US'
                }
            }
            SETTINGS offlineServicing  {
                COMPONENT Microsoft-Windows-PnpCustomizationsNonWinPE {
                    ELEMENT DriverPaths {
                        ELEMENT PathAndCredentials -Attributes 'keyValue=1' -TypeAdd {
                            ELEMENT Path '\Drivers'
                        }
                    }
                }
            }
        }  | get-OuterXML | should be (COntrolXML).DocumentElement.OuterXml

    }

}


