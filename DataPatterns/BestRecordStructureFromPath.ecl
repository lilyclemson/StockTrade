/***
 * Function macro that allows you to call BestRecordStructure knowing only its
 * path.  The path is examined to determine its underlying type, record
 * structure and (if necessary) other metadata information needed in order to
 * construct a DATASET declaration for it.  The dataset is then passed to the
 * BestRecordStructure() function macro for evaluation.
 *
 * For non-flat files, it is important that a record definition be available
 * in the file's metadata.  For just-sprayed files, this is commonly defined
 * in the first line of the file and furthermore that the "Record Structure
 * Present" option in the spray dialog box had been checked.
 *
 * Note that this function requires HPCC Systems version 6.4.0 or later.  It
 * leverages the dynamic record lookup capabilities added to that version and
 * described in https://hpccsystems.com/blog/file-layout-resolution-compile-time.
 *
 * @param   path            The full path to the file to profile; REQUIRED
 * @param   sampling        A positive integer representing a percentage of
 *                          the file to examine, which is useful when analyzing a
 *                          very large dataset and only an estimatation is
 *                          sufficient; valid range for this argument is
 *                          1-100; values outside of this range will be
 *                          clamped; OPTIONAL, defaults to 100 (which indicates
 *                          that the entire dataset will be analyzed)
 */
EXPORT BestRecordStructureFromPath(path, sampling = 100) := FUNCTIONMACRO
    IMPORT DataPatterns;
    IMPORT Std;

    // Function for gathering metadata associated with a file path
    LOCAL GetFileAttribute(STRING attr) := NOTHOR(Std.File.GetLogicalFileAttribute(path, attr));

    // Gather certain metadata about the given path
    LOCAL fileKind := GetFileAttribute('kind');
    LOCAL sep := GetFileAttribute('csvSeparate');
    LOCAL term := GetFileAttribute('csvTerminate');
    LOCAL quoteChar := GetFileAttribute('csvQuote');
    LOCAL escChar := GetFileAttribute('csvEscape');
    LOCAL headerLineCnt := GetFileAttribute('headerLength');

    // Dataset declaration for a delimited file
    LOCAL csvDataset := DATASET
        (
            path,
            RECORDOF(path, LOOKUP),
            CSV(HEADING(headerLineCnt), SEPARATOR(sep), TERMINATOR(term), QUOTE(quoteChar), ESCAPE(escChar))
        );

    // Dataset declaration for a flat file
    LOCAL flatDataset := DATASET
        (
            path,
            RECORDOF(path, LOOKUP),
            FLAT
        );

    // The returned value needs to be in a common format; dynamically determine
    // the record structure of the BestRecordStructure result so it can be used
    // to coerce the individual Profile calls (and to provide an empty dataset
    // in case of an error)
    LOCAL CommonResultRec := RECORDOF(DataPatterns.BestRecordStructure(DATASET([], {STRING s})));

    LOCAL RunBestRecordStructure(tempFile, _sampleSize) := FUNCTIONMACRO
        LOCAL theResult := DataPatterns.BestRecordStructure(tempFile, _sampleSize);

        RETURN PROJECT
            (
                theResult,
                TRANSFORM
                    (
                        CommonResultRec,
                        SELF := LEFT
                    )
            );
    ENDMACRO;

    LOCAL resultStructure := CASE
        (
            fileKind,
            'flat'  =>  RunBestRecordStructure(flatDataset, sampling),
            'csv'   =>  RunBestRecordStructure(csvDataset, sampling),
            ERROR(DATASET([], CommonResultRec), 'Cannot run BestRecordStructure on file of kind "' + fileKind + '"')
        );

    RETURN resultStructure;
ENDMACRO;
