*** Settings ***
Documentation       Creating a robot to order some robots
Library    RPA.Browser.Selenium
Library    RPA.HTTP
Library    RPA.Tables
Library    RPA.PDF
Library    RPA.Archive
Library    RPA.Robocorp.Vault
Library    RPA.Dialogs

*** Tasks ***
Order Robots
    Site Input and Open Browser
    Load Credentials and Log In
    Change Tab
    Download CSV
    Fill and Submit Forms
    ZIP the PDFs
    [Teardown]    Finish and Close Everything

*** Keywords ***
Site Input and Open Browser
    Add heading       Page Address
    Add text input    url
    ...    label=Url
    ...    placeholder=Enter url here
    ...    rows=5
    ${url}=    Run dialog
    Open Browser    ${url}

Open Browser
    [Arguments]    ${url}
    Open Available Browser    ${url}[url]    auto_close=${FALSE}
    
Load Credentials and Log In
    ${secret}=    Get Secret    credentials
    Log In    ${secret}

Log In
    [Arguments]    ${secret}
    Input Text    username    ${secret}[username]
    Input Password    password    ${secret}[password]
    Submit Form
    Wait Until Page Contains Element    id:sales-form

Change Tab
    Wait Until Page Contains Element    css:#root > header > div > ul > li:nth-child(2) > a
    Click Element    css:#root > header > div > ul > li:nth-child(2) > a
    Wait Until Page Contains Element    css:#root > div > div.modal > div > div > div > div > div > button.btn.btn-dark
    Click Button    css:#root > div > div.modal > div > div > div > div > div > button.btn.btn-dark
Download CSV
    Download    https://robotsparebinindustries.com/orders.csv

Fill and Submit Forms
    ${orders}=    Read table from CSV    orders.csv    header=True
    FOR    ${order}    IN    @{orders}
        Fill Forms    ${order}
    END
    

Fill Forms
    [Arguments]    ${order}
    # Wait Until Page Contains Element    css:#head
    Select From List By Index    css:#head    ${order}[Head]
    Click Element    css:#root > div > div.container > div > div.col-sm-7 > form > div:nth-child(2) > div > div:nth-child(${order}[Body]) > label
    Input Text    css:#root > div > div.container > div > div.col-sm-7 > form > div:nth-child(3) > input   ${order}[Legs]
    Input Text    css:#root > div > div.container > div > div.col-sm-7 > form > div:nth-child(4) > input    ${order}[Address]
    Click Button    css:#preview
    Click Button    css:#order
    ${error}=    Is Element Enabled    css:#root > div > div.container > div > div.col-sm-7 > div.alert.alert-danger
    WHILE    ${error}== True
        Click Button    css:#order
        ${error}=    Is Element Enabled    css:#root > div > div.container > div > div.col-sm-7 > div.alert.alert-danger
    END
        
    Save Data    ${order}
    Click Button    css:#order-another
    TRY
        Wait Until Page Contains Element    css:#root > div > div.modal > div > div > div > div > div > button.btn.btn-dark
    FINALLY
        Click Button    css:#root > div > div.modal > div > div > div > div > div > button.btn.btn-dark
    END


Save Data
    [Arguments]    ${order}
    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt_html}    ${OUTPUT_DIR}${/}orders${/}robot-order-${order}[Order number].pdf
    Screenshot    css:#robot-preview-image    ${OUTPUT_DIR}${/}imgs${/}robot${order}[Order number].png
    ${image}=    Create List    ${OUTPUT_DIR}${/}imgs${/}robot${order}[Order number].png
    Add Files To Pdf   ${image}    ${OUTPUT_DIR}${/}orders${/}robot-order-${order}[Order number].pdf    append=True

ZIP the PDFs
    Archive Folder With Zip    ${OUTPUT_DIR}${/}orders    ${OUTPUT_DIR}${/}orders.zip

Finish and Close Everything
    Click Button    Log out
    Close Browser