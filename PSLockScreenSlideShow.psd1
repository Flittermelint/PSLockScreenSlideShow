#
# Module manifest for module 'PSLockScreenSlideShow'
#
# Generated by: Frank Lindenblatt (Flittermelint)
#
# Updated on: 2024-08-18
#
# Inspired by:  https://github.com/nccgroup/Change-Lockscreen 
#
@{
    RootModule        = 'PSLockScreenSlideShow.psm1'

    ModuleVersion     = '0.0.2'

    GUID              = '96e1d3ad-98d1-4daa-a150-9585c9e97df5'

    Author            = 'Frank Lindenblatt (Flittermelint)'

    Copyright         = 'Copyright (c) 2024 Frank Lindenblatt (Flittermelint), licensed under the MIT License.'

    Description       = @'
Set single lockscreen image or display multiple images as slideshow.
In contrast to the OS slideshow, each image will always be shown alone (no collage).
Images will be displayed in the alphabetical order of the filenames (no randomness).
Display time of each image can individually be defined as part of the filename.
'@

    PowerShellVersion = '5.1'

    FileList          = @('PSLockScreenSlideShow.ps1')

    PrivateData = @{

        PSData = @{

            Tags       = @('powershell', 'lockscreen', 'slideshow', 'image')

            ProjectUri = 'https://github.com/Flittermelint/PSLockScreenSlideShow'

            LicenseUri = 'https://github.com/Flittermelint/PSLockScreenSlideShow/raw/main/LICENSE'

            IconUri    = 'https://github.com/Flittermelint/PSLockScreenSlideShow/raw/main/Images/PSLockScreenSlideShow.Logo.png'
        }
    }
}
