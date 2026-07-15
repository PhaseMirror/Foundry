\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{tengwarthesis}[2023/06/02 Tengwar Thesis]

% Written by Níckolas de Aguiar Alves (alves-nickolas.github.io). Partially inspired by (and adapted from) Martin Helsø's https://www.overleaf.com/latex/templates/uio-mathematics-masters-thesis/dhbqpjyhjmgd

%% OPTIONS AND LOAD CLASS
\newif\ifenglishonly\englishonlyfalse % No portuguese
\newif\ifnoglos\noglosfalse % No Glossaries
\newif\ifnotoc\notocfalse % No Table of Contents
\newif\ifhyper\hypertrue % Turn on/off colored hyperlinks
\newif\ifcatcard\catcardtrue % Turn on/off catalog card generation
\DeclareOption{englishonly}{\englishonlytrue}
\DeclareOption{noglos}{\noglostrue}
\DeclareOption{notoc}{\notoctrue}
\DeclareOption{nohyper}{\hyperfalse}
\DeclareOption{nocatcard}{\catcardfalse}
\DeclareOption*{\PassOptionsToClass{\CurrentOption}{memoir}}
\ProcessOptions\relax
\LoadClass{memoir}

%% PACKAGES

\RequirePackage[svgnames]{xcolor} % Color, which is clashing with standalone when I put it below for some reason

%% Standalone
\RequirePackage{standalone} % Improved inputs from external documents

%% Silence
\RequirePackage{silence} % Silences undesired warnings
\WarningFilter[pagecolorcrop]{pagecolor}{\nopagecolor does not work with} %nopagecolor doesn't work with memoir's crop functionality, and hence the background color is not 'none', but 'white'. We want to suppress pagecolor's warning
\WarningFilter[pagesltscontinue]{pageslts}{Option pagecontinue is false:} %pagecontinue is false
\WarningFilter[pagesltscontinue]{pageslts}{Option pagecontinue is false:} %pagecontinue is false

%% Encoding
\RequirePackage{fontspec}
\defaultfontfeatures{Scale=MatchLowercase, Ligatures=TeX}
\setmonofont{Latin Modern Mono}
\setmainfont{EB Garamond}[
    SmallCapsFeatures = {Letters = SmallCaps},
    Ligatures = {Common, TeX},
    Numbers = {Proportional, Lining},
    RawFeature=+calt,]
\setsansfont{Libertinus Sans}

%% Fonts and Typography
\RequirePackage[verbose=silent,final]{microtype} % Improved tipography
\DeclareMicrotypeAlias{EBGaramond-TU}{TU-basic}
\RequirePackage{kantlipsum} % Fill space with lorem ipsum
\RequirePackage{mwe} % Creating examples of document for the template
\RequirePackage[lowtilde]{url} % Manage typed urls
\RequirePackage{soul} % Provides hyphenatable spacing out (letterspacing), underlining, striking out, etc.

%% Mathematics
\RequirePackage{mathpackages}
\RequirePackage[warnings-off={mathtools-colon,mathtools-overbracket}]{unicode-math}
\setmathfont{Garamond Math}[StylisticSet={2,7,9,10}]

\AtBeginDocument{
    \let\real\Re \DeclareDocumentCommand\Re{g}{\IfNoValueTF{#1}{\operatorname{Re}}{\fbraces{\lbrace}{\rbrace}{\operatorname{Re}}{#1}}}
    \let\imaginary\Im \DeclareDocumentCommand\Im{g}{\IfNoValueTF{#1}{\operatorname{Im}}{\fbraces{\lbrace}{\rbrace}{\operatorname{Im}}{#1}}}
} %unicode-math redefines Re and Im at the start of the document, so this ensures the glyphs are correct (code taken from physics)

%% Language Support
\RequirePackage[english]{babel}
\RequirePackage{csquotes}

%% Graphics
%\RequirePackage[svgnames]{xcolor} % loaded by mathphys
\RequirePackage{graphicx} % Import figures
	\graphicspath{{./images/}{./pictures/}} % Path for figures
\ActivateWarningFilters[pagecolorcrop]
\RequirePackage[nopagecolor=white]{pagecolor} %page color
\DeactivateWarningFilters[pagecolorcrop]

%% Organising Tools
\RequirePackage{comment}                                 % Multiline comments

\RequirePackage[obeyFinal, 
                color       = LightGray,
                bordercolor = LightGray,
                textsize    = footnotesize,
                figwidth    = 0.99\linewidth,
                prependcaption]{todonotes} %Todonotes
\setuptodonotes{noline}
\newcommand{\todoalert}[2][]{\todo[color=LightCoral,bordercolor=LightCoral, #1]{#2}}
%\setlength{\marginparwidth}{2.5cm} %Todo notes can be in the margin

%% Lists
\RequirePackage{enumitem}

%% Miscelaneous
\RequirePackage{academicons}
\RequirePackage{ifdraft} % Ifdraft functionalities
\RequirePackage{xspace} % Better spacing
\RequirePackage{calc} % Allows arithmetic
\RequirePackage{booktabs} % Horizontal rules in tables
\RequirePackage{placeins} % FloatBarrier
\RequirePackage[hang, 
                small,
                %labelfont=bf,
                up,
                %textfont=it,
                up]{caption} % Custom figure/table captions 
\RequirePackage{subcaption} % Subfigures and subtables
    \captionsetup{subrefformat=parens} %configures subreferences when captioning subfigures
\RequirePackage{xparse} % Updated command-creation facilities 
\RequirePackage{etoolbox} % more package-creation facilities
\RequirePackage{multicol} % double columns
\RequirePackage{ifthen} % If-then structures
\RequirePackage{adforn} % Extra symbols
\RequirePackage[perpage,symbol*]{footmisc} % Footnote symbols restart every page
\RequirePackage{afterpage} % used to restore pagecolor after the cover
\ActivateWarningFilters[pagesltscontinue]
\RequirePackage[pagecontinue=false]{pageslts} % used to count total number of pages
\DeactivateWarningFilters[pagesltscontinue]

\ifoptionfinal{\newcommand{\reditout}[1]{}}{\newcommand{\reditout}[1]{\todoalert{Consider removing red text}\begingroup\color{red}#1\endgroup}} % deciding on whether to keep chunk of text

\ifoptionfinal{\newcommand{\neworupdated}[1]{#1}}{\newcommand{\neworupdated}[1]{\todo[color=ForestGreen!40,bordercolor=ForestGreen!40]{New or updated}\begingroup\color{green!55!black}#1\endgroup}} % new paragraph

%% Bibliography
\RequirePackage[backend    = biber, 
                style      = ext-authoryear-comp,
                sorting    = nyvt, 
                backref    = true,
                articlein  = false,
                uniquename = false,
                doi        = true,
                date       = year,
                urldate    = comp,
                dashed     = true]{biblatex} %Custom bibliography
\renewcommand*{\bibnamedash}{\rule[.4ex]{3em}{.5pt} \,}
\renewcommand*{\bibsetup}{%
  \interlinepenalty=10000\relax % default is 5000
  \widowpenalty=10000\relax
  \clubpenalty=10000\relax
  \raggedbottom
  \frenchspacing
  \biburlsetup}

\DeclareNameFormat{labelname}{%
  \ifcase\value{uniquename}%
    \usebibmacro{name:family}
      {\namepartfamily}
      {\namepartgiven}
      {\namepartprefix}
      {\namepartsuffix}%
  \or
    \usebibmacro{name:given-family}
      {\namepartfamily}
      {\namepartgiveni}
      {\namepartprefix}
      {\namepartsuffixi}%
  \or
    \usebibmacro{name:given-family}
      {\namepartfamily}
      {\namepartgiven}
      {\namepartprefix}
      {\namepartsuffix}%
  \fi
  \usebibmacro{name:andothers}}

\DeclareFieldFormat{urldate}{\addcomma\space\bibstring{urlseen}\space#1}%no parentheses on urldate

    \addbibresource{bib.bib} %Load references

%% Glossaries
\RequirePackage[abbreviations,nogroupskip,nonumberlist,automake=immediate]{glossaries-extra}
\newglossarystyle{twocollist}{
    \setglossarystyle{list}\BeforeBeginEnvironment{theglossary}{\begin{multicols}{2}}
    \AfterEndEnvironment{theglossary}{\end{multicols}}
    }
\glsdisablehyper
\setabbreviationstyle{long-short}
\makeglossaries

\GlsXtrEnableEntryUnitCounting{abbreviation}{1}{chapter} %resetting abbreviations every chapter (https://tex.stackexchange.com/a/646628/144146)
\newcommand*{\restoreusedflag}{} 
\preto\glslinkpresetkeys{%
  \ifnumcomp{\glsentrycurrcount{\glslabel}}{=}{0}
    {%
      \ifglsused{\glslabel}
        {\renewcommand*\restoreusedflag{\csuse{@@glsunset}{\glslabel}}}{}%
      \glsreset{\glslabel}%
    }{}%
}
\preto\glspostlinkhook{%
  \ifglsused{\glslabel}{}{\restoreusedflag}%
  \renewcommand*{\restoreusedflag}{}%
}

\loadglsentries{abbrvs} %loading abbreviations from file

%% Cross references
\RequirePackage{varioref}
\ifhyper
    \RequirePackage[colorlinks  = true, 
                urlcolor        = blue, 
                anchorcolor     = blue, 
                citecolor       = blue, 
                filecolor       = blue, 
                linkcolor       = blue, 
                menucolor       = blue, 
                linktocpage     = true, 
                bookmarks       = true,
                pdfusetitle]{hyperref} % Hyperlinks in pdf
\else
    \RequirePackage[colorlinks  = false, 
                urlcolor        = blue, 
                anchorcolor     = blue, 
                citecolor       = blue, 
                filecolor       = blue, 
                linkcolor       = blue, 
                menucolor       = blue, 
                linktocpage     = true, 
                bookmarks       = true,
                pdfusetitle]{hyperref} % Hyperlinks in pdf
\fi
\RequirePackage{bookmark} % Among other things, allows to remove last chapters from inside a part (bibliography doesn't belong to part 2)
\RequirePackage{memhfixc} % Memoir + Hyperref
\RequirePackage[capitalize]{cleveref} % Clever references
\RequirePackage[retainorgcmds]{IEEEtrantools} % Commands from the IEEEtran.cls class file, loaded last to avoid clash with cleveref

%% FRONTMATTER
%% Author Surname and Prename
\def\@authorsurname{\@empty}
\def\@authorprename{\@empty}
\renewcommand{\author}[2]{\gdef\@authorprename{#1}\gdef\@authorsurname{#2}\gdef\@author{#1 #2}\gdef\theauthor{\@author}}

%% Subtitle
\def\@subtitle{\@empty}
\providecommand{\subtitle}[1]{\gdef\@subtitle{#1}}
\renewcommand{\subtitle}[1]{\gdef\@subtitle{#1}}

%% Version
\def\@version{\@empty}
\providecommand{\version}[1]{\gdef\@version{#1}}
\renewcommand{\version}[1]{\gdef\@version{#1}}

%% ORCID
\def\@orcid{\@empty}
\providecommand{\orcid}[1]{\gdef\@orcid{#1}}
\renewcommand{\orcid}[1]{\gdef\@orcid{#1}}

%% Location
\def\@location{\@empty}
\def\@city{\@empty}
\def\@country{\@empty}
\providecommand{\location}[3][]{
        \gdef\@city{#2}
        \gdef\@country{#3}
    \IfNoValueTF{#1}{
        \gdef\@location{#2}
    }{
        \gdef\@location{#2 -- #1}
    }
}
\renewcommand{\location}[3][]{
        \gdef\@city{#2}
        \gdef\@country{#3}
    \IfNoValueTF{#1}{
        \gdef\@location{#2}
    }{
        \gdef\@location{#2 -- #1}
    }
}

%% Defense Year
\def\@defenseyear{\@empty}
\providecommand{\defenseyear}[1]{\gdef\@defenseyear{#1}}
\renewcommand{\defenseyear}[1]{\gdef\@defenseyear{#1}}

%% University
\def\@universityname{\@empty}
\def\@ptuniversityname{\@empty}
\DeclareDocumentCommand\universityname{ o m }{
    \gdef\@universityname{#2}
    \IfNoValueTF{#1}{}{\gdef\@ptuniversityname{#1}}
}

%% Program
\def\@programname{\@empty}
\def\@ptprogramname{\@empty}
\DeclareDocumentCommand\programname{ o m }{
    \gdef\@programname{#2}
    \IfNoValueTF{#1}{}{\gdef\@ptprogramname{#1}}
}

%% Cover Decoration
\def\@coverdecoration{\@empty}
\providecommand{\coverdecoration}[1]{\gdef\@coverdecoration{#1}}
\renewcommand{\coverdecoration}[1]{\gdef\@coverdecoration{#1}}

%% Advisor
\def\@advisor{\@empty}
\def\@advisorsurname{\@empty}
\def\@advisorprename{\@empty}
\providecommand{\advisor}[3][]{\gdef\@advisorprename{#2}\gdef\@advisorsurname{#3}\gdef\@advisor{#1 #2 #3}}
\renewcommand{\advisor}[3][]{\gdef\@advisorprename{#2}\gdef\@advisorsurname{#3}\gdef\@advisor{#1 #2 #3}}

%% Co-advisor
\def\@coadvisor{\@empty}
\def\@coadvisorsurname{\@empty}
\def\@coadvisorprename{\@empty}
\providecommand{\coadvisor}[3][]{\gdef\@coadvisorprename{#2}\gdef\@coadvisorsurname{#3}\gdef\@coadvisor{#1 #2 #3}}
\renewcommand{\coadvisor}[3][]{\gdef\@coadvisorprename{#2}\gdef\@coadvisorsurname{#3}\gdef\@coadvisor{#1 #2 #3}}

%% Presentation Note
\def\@presentationnote{\@empty}
\providecommand{\presentationnote}[1]{\gdef\@presentationnote{#1}}
\renewcommand{\presentationnote}[1]{\gdef\@presentationnote{#1}}

%% Catalographic Card Info
\newcounter{totfigures} %https://tex.stackexchange.com/a/55583/144146 with extra counting due to subfigures and some simplification
\providecommand\totfig{} 
\AtEndDocument{%
  \immediate\write\@mainaux{%
    \string\gdef\string\totfig{\number\value{totfigures}}%
  }%
}
\AtEndEnvironment{figure}{\addtocounter{totfigures}{\value{subfigure}}%
\ifnum\value{subfigure}>0%
\else
\addtocounter{totfigures}{1}% if there are no subfigures, add 1 (for the figure itself)
\fi%
}

\def\@thesistype{\@empty}
\providecommand{\thesistype}[1]{\gdef\@thesistype{#1}}
\renewcommand{\thesistype}[1]{\gdef\@thesistype{#1}}

%% Statement of Compliance with Committee Observations
\newif\ifcompliance\compliancefalse
\def\@declaracaodeatendimento{\@empty}
\def\@statementofcompliance{\@empty}
\providecommand{\declaracaodeatendimento}[1]{\gdef\@declaracaodeatendimento{#1}\compliancetrue}
\renewcommand{\declaracaodeatendimento}[1]{\gdef\@declaracaodeatendimento{#1}\compliancetrue}
\providecommand{\statementofcompliance}[1]{\gdef\@statementofcompliance{#1}\compliancetrue}
\renewcommand{\statementofcompliance}[1]{\gdef\@statementofcompliance{#1}\compliancetrue}

%% Signature Sheet
\def\@signsheet{\@empty}
\providecommand{\signsheet}[1]{\gdef\@signsheet{#1}}
\renewcommand{\signsheet}[1]{\gdef\@signsheet{#1}}

%% Funding Statement
\def\@fundingstatement{\@empty}
\providecommand{\fundingstatement}[1]{\gdef\@fundingstatement{#1}}
\renewcommand{\fundingstatement}[1]{\gdef\@fundingstatement{#1}}

%% Epigraph
\def\@epigraph{\@empty}
\def\@epigraphlist{\@empty}
\def\@source{\@empty}
\setlength\epigraphwidth{25em}
\let\Epigraph\epigraph
\providecommand{\epigraph}[2]{\gdef\@epigraph{#1}\gdef\@source{#2}}
\renewcommand{\epigraph}[2]{\gdef\@epigraph{#1}\gdef\@source{#2}}
\providecommand{\epigraphlist}[2]{\gdef\@epigraphlist{#1}}
\renewcommand{\epigraphlist}[2]{\gdef\@epigraphlist{#1}}

%% Abstract
\def\@abstract{\@empty}
\def\@keywords{\@empty}
\def\@keywordsa{\@empty}
\def\@keywordsb{\@empty}
\def\@keywordsc{\@empty}
\def\@keywordsd{\@empty}
\def\@keywordse{\@empty}
\renewcommand{\abstract}[1]{\gdef\@abstract{#1}}
\DeclareDocumentCommand\keywords{ m g g g g }{% keywords
        \gdef\@keywordsa{#1}
        \IfNoValueTF{#2}{}{\gdef\@keywordsb{#2}}
        \IfNoValueTF{#3}{}{\gdef\@keywordsc{#3}}
        \IfNoValueTF{#4}{}{\gdef\@keywordsd{#4}}
        \IfNoValueTF{#5}{}{\gdef\@keywordse{#5}}
        \xdef\@keywords{{\if!\@keywordsa!\else\@keywordsa\fi}{\if!\@keywordsb!\else, \@keywordsb\fi}{\if!\@keywordsc!\else, \@keywordsc\fi}{\if!\@keywordsd!\else, \@keywordsd\fi}{\if!\@keywordse!\else, \@keywordse\fi}}
    }

%% Resumo
\def\@resumo{\@empty}
\def\@ptkeywords{\@empty}
\def\@ptkeywordsa{\@empty}
\def\@ptkeywordsb{\@empty}
\def\@ptkeywordsc{\@empty}
\def\@ptkeywordsd{\@empty}
\def\@ptkeywordse{\@empty}
\providecommand{\resumo}[1]{\gdef\@resumo{#1}}
\renewcommand{\resumo}[1]{\gdef\@resumo{#1}}
\DeclareDocumentCommand\palavraschave{ m g g g g }{% keywords
        \gdef\@ptkeywordsa{#1}
        \IfNoValueTF{#2}{}{\gdef\@ptkeywordsb{#2}}
        \IfNoValueTF{#3}{}{\gdef\@ptkeywordsc{#3}}
        \IfNoValueTF{#4}{}{\gdef\@ptkeywordsd{#4}}
        \IfNoValueTF{#5}{}{\gdef\@ptkeywordse{#5}}
        \xdef\@ptkeywords{{\if!\@ptkeywordsa!\else\@ptkeywordsa\fi}{\if!\@ptkeywordsb!\else, \@ptkeywordsb\fi}{\if!\@ptkeywordsc!\else, \@ptkeywordsc\fi}{\if!\@ptkeywordsd!\else, \@ptkeywordsd\fi}{\if!\@ptkeywordse!\else, \@ptkeywordse\fi}}
    }

%% Acknowledgments
\def\@acknowledgments{\@empty}
\newcommand{\acknowledgments}[1]{\gdef\@acknowledgments{#1}}

%% Dedication
\def\@dedication{\@empty}
\newcommand{\dedication}[1]{\gdef\@dedication{#1}}

%% Preface
\def\@preface{\@empty}
\def\@signas{\@empty}
\newif\ifnosignature\nosignaturefalse
\DeclareDocumentCommand\preface{ s o m }{
    \IfBooleanTF{#1}
    {\nosignaturetrue\gdef\@preface{#3}}
    {\gdef\@preface{#3}
        \IfNoValueTF{#2}{}{\gdef\@signas{#2}}
    }
}

%% Maketitle
\renewcommand{\maketitle}{
%% Front Cover
\thispagestyle{empty}
\begin{KeepFromToc}
    \pdfbookmark{Front Cover}{frontcover}
\end{KeepFromToc}
\pagenumbering{Roman}
\colorlet{saved}{.}
\definecolor{CoverBlue}{HTML}{000040}
\definecolor{CoverGold}{HTML}{FCC200}
\newpagecolor{CoverBlue}
\color{CoverGold}
\newcommand\restorecolor{\color{saved}}
\afterpage{\restorepagecolor\aftergroup\restorecolor}
\begin{center}
        {\if!\@universityname!
        \else
            \@universityname
        \fi}

        {\if!\@programname!
        \else
            \@programname
        \fi}

        \vspace{5ex}
        
        {\Large%
        \theauthor
        }

        \vfill
        
        {\HUGE\center%
        \thetitle}
        {\if!\@subtitle!%
        \else%
            \LARGE\center%
        \@subtitle%
        \fi}

        \vfill
        \null        
        {\if!\@coverdecoration!
            \vfill
        \else\centering
            \@coverdecoration
        \fi}
        \null
        {\if!\@version!
        \else\centering
            \ifoptionfinal{}{\textsc{Draft as of: \@version}}
        \fi}
        \vfill

        {\if!\@location!
        \else
            \@location
        \fi}

        {\if!\@defenseyear!
        \else
            \@defenseyear
        \fi}
\end{center}

\newpage\null\thispagestyle{empty}

\frontmatter

%% Cover Page
\newpage
\thispagestyle{empty}
\begin{KeepFromToc}
    \pdfbookmark{Cover Page}{coverpage}
\end{KeepFromToc}
\begin{center}
        {\Large%
        \theauthor%
        \if!\@orcid!
        \else
            \textsuperscript{\href{\@orcid}{\textcolor[HTML]{a6ce35}{\aiOrcid}}}
        \fi
        }

        \vspace{15ex}
        \if!\@advisor!%
        \vspace{15ex}
        \fi
        
        {\HUGE\center%
        \thetitle}
        {\if!\@subtitle!%
        \else%
            \LARGE\center%
        \@subtitle%
        \fi}
        
        \vfill

        \end{center}
        \null\hfill\begin{minipage}{0.65\textwidth}
            {\if!\@presentationnote!%
            \else%
            \@presentationnote%
            \vspace{1ex}%
            \fi}

            {\if!\@advisor!%
            \else%
            Advisor: \@advisor%
            \vspace{1ex}%
            \fi}

            {\if!\@coadvisor!%
            \else%
            Co-advisor: \@coadvisor%
            \fi}
        \end{minipage}
        \begin{center}
        
        \vfill

        {\if!\@location!
        \else
            \@location
        \fi}

        {\if!\@defenseyear!
        \else
            \@defenseyear
        \fi}
\end{center}

%% Catalographic Card
\newpage
\thispagestyle{empty}
\ifcatcard
\begin{KeepFromToc}
    \pdfbookmark{Catalographic Card}{catcard}
\end{KeepFromToc}
\ifenglishonly
    \begin{center}
    \null
    \vfill
    \fbox{\begin{minipage}{12.5 cm}\setlength{\parindent}{1.5em}\noindent
    \MakeUppercase{\@authorsurname}, \@authorprename \par
    \thetitle {\if!\@subtitle!\else: \@subtitle\fi} / {\theauthor} --- \@city, \if!\@universityname!\else\@universityname, \fi\@defenseyear.\par\vspace{1ex}
    \lastpageref*{pagesLTS.roman}, \lastpageref*{pagesLTS.arabic} p.: \totfig{} il.\par\vspace{1ex}
    {\if!\@advisor!\else%
    Advisor: \@advisorprename{} \@advisorsurname{}\par\vspace{1ex}\fi}
    {\if!\@coadvisor!\else%
    Coadvisor: \@coadvisor\par\vspace{1ex}\fi}
    \if!\@thesistype!\else%
    \@thesistype{} --- \if!\@universityname!\else\@universityname, \fi\if!\@programname!\else\@programname, \fi\@defenseyear.\par\vspace{1ex}\fi

    {1. \@keywordsa.}{\if!\@keywordsb!\else{} %
    2. \@keywordsb.\fi}{\if!\@keywordsc!\else{} %
    3. \@keywordsc.\fi}{\if!\@keywordsd!\else{} %
    4. \@keywordsd.\fi}{\if!\@keywordse!\else{} %
    5. \@keywordse.\fi}{\if!\@advisor!{} I. Title.\else{} I. \MakeUppercase{\@advisorsurname}, \@advisorprename. II. {\if!\@coadvisor!%
    \@programname, \@defenseyear. III. Title.    
    \else%
    \MakeUppercase{\@coadvisorsurname}, \@coadvisorprename. III. \@programname, \@defenseyear. IV. Title.%
    \fi}\fi}

    \end{minipage}}
    \end{center}
    \cleardoublepage
\else%cat card in Portuguese
    \begin{center}
    \null
    \vfill
    \fbox{\begin{minipage}{12.5 cm}\setlength{\parindent}{1.5em}\noindent
    \MakeUppercase{\@authorsurname}, \@authorprename \par
    \thetitle {\if!\@subtitle!\else: \@subtitle\fi} / {\theauthor} --- \@city, \if!\@ptuniversityname!\else\@ptuniversityname, \fi\@defenseyear.\par\vspace{1ex}
    \lastpageref*{pagesLTS.roman}, \lastpageref*{pagesLTS.arabic} p.: \totfig{} il.\par\vspace{1ex}
    {\if!\@advisor!\else%
    Orientador: \@advisorprename{} \@advisorsurname{}\par\vspace{1ex}\fi}
    {\if!\@coadvisor!\else%
    Co-orientador: \@coadvisor\par\vspace{1ex}\fi}
    \if!\@thesistype!\else%
    \@thesistype{} --- \if!\@ptuniversityname!\else\@ptuniversityname, \fi\if!\@ptprogramname!\else\@ptprogramname, \fi\@defenseyear.\par\vspace{1ex}\fi

    {1. \@ptkeywordsa.}{\if!\@ptkeywordsb!\else{} %
    2. \@ptkeywordsb.\fi}{\if!\@ptkeywordsc!\else{} %
    3. \@ptkeywordsc.\fi}{\if!\@ptkeywordsd!\else{} %
    4. \@ptkeywordsd.\fi}{\if!\@ptkeywordse!\else{} %
    5. \@ptkeywordse.\fi}{\if!\@advisor!{}  I. Título.\else{} I. \MakeUppercase{\@advisorsurname}, \@advisorprename. II. {\if!\@coadvisor!%
    \@ptprogramname, \@defenseyear. III. Título.    
    \else%
    \MakeUppercase{\@coadvisorsurname}, \@coadvisorprename. III. \@ptprogramname, \@defenseyear. IV. Título.%
    \fi}\fi}

    \end{minipage}}
    \end{center}
    \cleardoublepage
\fi
\else%no catcard
\fi

%Statement of Compliance
    \ifcompliance
    \thispagestyle{empty}
    \begin{KeepFromToc}
        \pdfbookmark{Statement of Compliance with Committee Observations}{declaration}
    \end{KeepFromToc}
    \null
    \vfill
    \if!\@declaracaodeatendimento!\null%
    \else{}%
    \@declaracaodeatendimento\fi\bigskip

    \if!\@statementofcompliance!\else{} %
    \@statementofcompliance\fi
    \vfill
    \null
    \vfill
    \clearpage\fi

%signature sheet
    \if!\@signsheet!\else{}
    \thispagestyle{empty}
    \begin{KeepFromToc}
        \pdfbookmark{Signature Sheet}{signatures}
    \end{KeepFromToc}
    \tikz[remember picture, overlay] \node at (current page.center) {\@signsheet};
    \clearpage\fi

%funding statement
    \if!\@fundingstatement!\else{}
    \thispagestyle{empty}
    \begin{KeepFromToc}
        \pdfbookmark{Funding Acknowledgment Sheet}{capes}
    \end{KeepFromToc}
    \null
    \vfill
    \@fundingstatement
    \vfill
    \null
    \vfill
    \cleardoublepage\fi

\if!\@dedication!
\else
    \thispagestyle{empty}
    \begin{KeepFromToc}
        \pdfbookmark{Dedication}{dedication}
    \end{KeepFromToc}
    \null
    \vfill
    \begin{center}
        \emph{\@dedication}
    \end{center}
    \vfill
    \null
    \vfill
    \cleardoublepage
\fi

\if!\@epigraphlist!
    \if!\@epigraph!
    \else
        \thispagestyle{empty}
        \begin{KeepFromToc}
            \pdfbookmark{Epigraph}{epigraph}
        \end{KeepFromToc}
        \null
        \vfill
        \begin{flushright}
            \Epigraph{\@epigraph}{\@source}
        \end{flushright}
        \cleardoublepage
    \fi
\else
    \setlength{\beforeepigraphskip}{\baselineskip}
    \setlength{\afterepigraphskip}{\baselineskip}
    \thispagestyle{empty}
    \begin{KeepFromToc}
        \pdfbookmark{Epigraph}{epigraph}
    \end{KeepFromToc}
    \null
    \vfill
    \begin{flushright}
        \begin{epigraphs}
            \@epigraphlist
        \end{epigraphs}
    \end{flushright}
    \setlength{\beforeepigraphskip}{0.5\baselineskip}
    \setlength{\afterepigraphskip}{0.5\baselineskip}
    \cleardoublepage
\fi
\let\epigraph\Epigraph
\let\Epigraph\relax

\if!\@resumo!
\else
    \chapter{Resumo}
    \@resumo\par\vskip\onelineskip
    
    \if!\@ptkeywords!
    \else
        \noindent%
        Palavras-chave: \@ptkeywords.
    \fi
    \cleardoublepage
\fi

\if!\@abstract!
\else
    \chapter{Abstract}
    \@abstract\par\vskip\onelineskip
    
    \if!\@keywords!
    \else
        \noindent%
        Keywords: \@keywords.
    \fi
    \cleardoublepage
\fi

\if!\@preface!
\else
\chapter{Preface}
\@preface
\ifnosignature\else
    \begin{flushright}
        \if!\@signas!
            \theauthor
        \else
            \@signas
        \fi
        
        \thedate
    \end{flushright}
\fi
\cleardoublepage
\fi

\if!\@acknowledgments!
\else
\chapter{Acknowledgments}
\@acknowledgments
\cleardoublepage
\fi

\ifnoglos\else
\printglossary[style=twocollist,type=abbreviations,title={Abbreviations}]
\cleardoublepage
\fi

\ifnotoc\else
\begin{KeepFromToc}
    \pdfbookmark{\contentsname}{Contents}
    \renewcommand*{\cftpartfont}{\normalfont\Large}
    \renewcommand*{\cftpartpagefont}{\normalfont\Large}
    \renewcommand*{\cftchapterfont}{\normalfont\large}
    \renewcommand*{\cftchapterpagefont}{\normalfont\large}
    \maxtocdepth{subsection}
    \setlength{\cftsubsectionindent}{5em}
    \tableofcontents
\end{KeepFromToc}
\fi

\mainmatter
}

%% MAINMATTER
%% Part Style
\renewcommand*{\partnamefont}{\normalfont\huge}
\renewcommand*{\partnumfont}{\normalfont\huge}
\renewcommand*{\parttitlefont}{\normalfont\Huge\center}

%% Chapter Style
\makechapterstyle{demonew}{%
\renewcommand*{\printchaptername}{\centering}
\renewcommand*{\printchapternum}{\chapnumfont
\ifanappendix \thechapter \else \numtoName{\c@chapter}\fi}
\renewcommand*{\chapnumfont}{\normalfont\Huge}\renewcommand*{\chaptitlefont}{\normalfont\Huge}
\renewcommand*{\printchaptertitle}[1]{%
\centering \chaptitlefont ##1}
\renewcommand*{\afterchaptertitle}{%
\vskip \afterchapskip}
\setlength{\beforechapskip}{3\baselineskip}
\renewcommand*{\printchapternonum}{%
\vphantom{\chapnumfont One}
\afterchapternum%
\vskip\topskip}
\setlength{\beforechapskip}{2\onelineskip}
}% end demo
\chapterstyle{demonew}

\newcommand*{\chapabstract}[1]{
\vspace{-\afterchapskip}
\vspace{\onelineskip}
\noindent\emph{#1}
}

%% Lower level sections
\numberwithin{equation}{section}
\setsecheadstyle{\Large\rmfamily\raggedright}
\setsubsecheadstyle{\large\rmfamily\raggedright}
\setsubsubsecheadstyle{\normalsize\rmfamily\raggedright}
\setparaheadstyle{\normalsize\rmfamily\raggedright}
\setsubparaheadstyle{\normalsize\rmfamily\raggedright}

%% Asterism
\newcommand{\fleuron}{\text{\adforn{68}}}

\newcommand{\asterism}{%
  \par\bigskip\noindent\hfill\huge\textcolor{ForestGreen}{\adforn{68}}\hfill\null\par\bigskip\normalsize
}

\renewcommand{\asterism}{%
  \par\bigskip\noindent\hfill\huge\adforn{50}\quad\adforn{3}\quad\adforn{22}\hfill\null\par\bigskip\normalsize
}

%% BACKMATTER
%% Makeback
\newcommand{\makeback}{
    \FloatBarrier
    \bookmarksetup{startatroot}
    \appendix}
\newcommand{\makefinal}{
    \emergencystretch=0.65em %https://tex.stackexchange.com/a/172000/144146
    \printbibliography[heading=bibintoc]
}

%% Headers and Footers
%\makepsmarks{plain}{\AddToShipoutPictureBG*{\includegraphics[page=1]{images/chaphex.pdf}}}
\copypagestyle{fancy}{ruled}
\renewcommand{\chaptermark}[1]{\markboth{#1}{#1}}
\renewcommand{\sectionmark}[1]{\markright{#1}}
\makeevenhead{fancy}{\thepage}{}{\leftmark}
\makeoddhead{fancy}{\rightmark}{}{\thepage}
\makeevenfoot{fancy}{}{}{}
\makeoddfoot{fancy}{}{}{}
\pagestyle{fancy}

%% MISC
%% Page Layout
\settypeblocksize{*}{0.72\stockwidth}{1.4142}
\setlrmargins{*}{*}{1}
\setulmargins{*}{*}{1}
\checkandfixthelayout[nearest]

%% Et cetera
\newcommand{\ie}{\emph{i.e.}\xspace} %id est
\newcommand{\eg}{\emph{e.g.}\xspace} %exempli gratia
\newcommand{\viz}{\emph{viz.}\xspace} %videre licet
\newcommand{\etc}{\emph{etc.}\xspace} %et cetera
\newcommand{\afort}{\emph{a fortiori}\xspace} %id est
\newcommand{\mutmut}{\emph{mutatis mutandis}\xspace} %mutatis mutandis
\newcommand{\cf}{\emph{cf.}\xspace} %conferatur
\renewcommand{\labelenumi}{\textnormal{\roman{enumi}.}} %Change first-order enumeration numbers to lowercase roman
\renewcommand\theenumi\labelenumi %Change references to enumeration numbers to match their labels in the list
