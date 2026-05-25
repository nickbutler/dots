function pdfit --description "Convert files to PDF using Chrome headless"
    if test (count $argv) -eq 0
        echo "Usage: pdfit <file> [file ...]"
        return 1
    end

    set chrome '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'

    for file in $argv
        set abs (realpath $file)
        set output (string replace -r '\.[^.]+$' '.pdf' $abs)
        echo "Converting $file -> $output"
        "$chrome" --headless --print-to-pdf="$output" "$abs"
    end
end
