*** Settings ***
Documentation       A robot for buying robots

Library             RPA.Tables
Library             RPA.HTTP
Library             RPA.Browser.Selenium
Library             RPA.PDF
Library             RPA.FileSystem
Library             RPA.Archive
Library             Dialogs
Library             RPA.Robocorp.Vault


*** Variables ***
${prefix}       none
${secret}


*** Tasks ***
A robot for buying robots
    Download the robot shopping list
    Log into the system
    Purchase all robots in list
    Zip all pdfs
    [Teardown]    Clean and close


*** Keywords ***
Download the robot shopping list
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True

Log into the system
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order    auto_close=False

Purchase all robots in list
    Log    Reading csv file
    Ask for file prefix
    ${secret}    Get Secret    option
    @{orders}    Read table from CSV    path=orders.csv    header=True    delimiters=,
    FOR    ${order}    IN    @{orders}
        Log    ${order}
        Click Element When Visible
        ...    //button[normalize-space()='${secret}[label]']    #//button[normalize-space()='Yep']
        Purchase a robot    ${order}
        Save receipt as PDF    ${order}
    END

Ask for file prefix
    ${prefix}    Get Value From User
    ...    message=Please enter a prefix for the pdf filenames
    ...    default_value=receipt-

Purchase a robot
    [Arguments]    ${order}
    Comment    Select robot head
    Wait Until Element Is Visible
    ...    //select[@id='head']

    Select From List By Index    //select[@id='head']    ${order}[Head]
    Comment    Select robot body
    Select Radio Button    body    ${order}[Body]

    Comment    Input legs
    Input Text
    ...    css:body > div:nth-child(2) > div:nth-child(2) > div:nth-child(1) > div:nth-child(2) > div:nth-child(1) > form:nth-child(2) > div:nth-child(3) > input:nth-child(3)
    ...    ${order}[Legs]

    Comment    Input Address
    Input Text    xpath://input[@id='address']    ${order}[Address]

    Comment    Preview robot
    Click Button When Visible    //button[@id='preview']

    Sleep    0.3 seconds

    Screenshot that robot    ${order}

    Punch that order button

Punch that order button
    Comment    Click on ORDER button
    ${can_i_order}    Is Element Visible    //button[@id='order']
    WHILE    ${can_i_order}
        Click Button    //button[@id='order']
        ${can_i_order}    Is Element Visible    //button[@id='order']
    END

Save receipt as PDF
    [Arguments]    ${order}
    Wait Until Element Is Visible
    ...    //*[@id="receipt"]

    ${receipt_html}
    ...    Get Element Attribute
    ...    //*[@id="receipt"]
    ...    outerHTML

    Html To Pdf
    ...    ${receipt_html}
    ...    ${CURDIR}${/}tmp${/}${prefix}${order}[Order number].pdf

    Log    Save receipt

    Add Watermark Image To Pdf
    ...    image_path=${CURDIR}${/}tmp${/}${prefix}${order}[Order number].png
    ...    source_path=${CURDIR}${/}tmp${/}${prefix}${order}[Order number].pdf
    ...    output_path=${CURDIR}${/}pdf${/}${prefix}${order}[Order number].pdf

    Log    Add image

    Click Button
    ...    //button[@id='order-another']

Screenshot that robot
    [Arguments]    ${order}
    Screenshot
    ...    //*[@id="robot-preview-image"]
    ...    ${CURDIR}${/}tmp${/}${prefix}${order}[Order number].png
    Log    Screenshot

Zip all pdfs
    Log    Zip all pdfs

    Archive Folder With ZIP
    ...    folder=${CURDIR}${/}pdf
    ...    archive_name=${CURDIR}${/}output${/}robotsales.zip
    ...    recursive=True
    ...    include=*.pdf
    ...    exclude=/.*

Clean and close
    Empty Directory
    ...    ${CURDIR}${/}tmp

    Empty Directory
    ...    ${CURDIR}${/}pdf

    Close All Browsers
