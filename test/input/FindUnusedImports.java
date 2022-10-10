package ca.example.vim;

import ca.example.vim.internal.Used;
import ca.example.vim.internal.Unused;

public class FindUnusedImports {

    public void example() {
        Used.doThing();

        // make sure these don't match
        UnusedNO
        NOUnused
        unused
    }
}
