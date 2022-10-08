package ca.example.vim;

import ca.example.internal.vim.Internal;
import ca.example.internal.vim.Internal.Interface;

public class ImportClassPackageNameMatchBug {
    public ImportClassPackageNameMatchBug() {}
}

// if we have a package and class with the same name, the plugin would remove the first one when building the import tree. This source file is used to validate the fix.

