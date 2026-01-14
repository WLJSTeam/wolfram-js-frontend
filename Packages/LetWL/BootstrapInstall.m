BeginPackage["LetWL`"]

Begin["`Private`"]

$projectURL = "https://github.com/lshifr/LetWL/archive/master.zip"

Replace[
    URLDownload[$projectURL],
    {
        $Failed :> $Failed,
        tempFile_ :> 
            With[{extracted = ExtractArchive[
                tempFile, 
                FileNameJoin[{$UserBaseDirectory, "Applications"}]
                ]},
                DeleteFile[tempFile];
                Replace[
                    extracted,
                    {
                        $Failed :> $Failed,
                        {dir_, ___} :> With[
                            {new = FileNameJoin[{DirectoryName @ dir, "LetWL"}]}
                            ,
                            If[DirectoryQ[new], 
                                DeleteDirectory[new, DeleteContents -> True]
                            ];
                            RenameDirectory[dir, new];
                            new
                        ]
                    }
                ]
            ]
    }
]

End[]

Block[{$ContextPath}, EndPackage[]]