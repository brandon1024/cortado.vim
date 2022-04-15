package ca.example.vim;

import ca.example.vim.internal.ImportedClass;
import ca.example.vim.external.Interface;

public @interface SimpleAnnotation {
    public SimpleAnnotation(ImportedClass c, Interface i) {}
}
