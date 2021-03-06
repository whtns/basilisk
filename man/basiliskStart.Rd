% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/basiliskStart.R
\name{basiliskStart}
\alias{basiliskStart}
\alias{basiliskStop}
\alias{basiliskRun}
\title{Start and stop \pkg{basilisk}-related processes}
\usage{
basiliskStart(env, fork = getBasiliskFork(), shared = getBasiliskShared())

basiliskStop(proc)

basiliskRun(
  proc = NULL,
  fun,
  ...,
  env,
  fork = getBasiliskFork(),
  shared = getBasiliskShared()
)
}
\arguments{
\item{env}{A \linkS4class{BasiliskEnvironment} object specifying the \pkg{basilisk} environment to use.

Alternatively, a string specifying the path to an environment, though this should only be used for testing purposes.

Alternatively, \code{NULL} to indicate that the base Conda installation should be used as the environment.}

\item{fork}{Logical scalar indicating whether forking should be performed on non-Windows systems, 
see \code{\link{getBasiliskFork}}.
If \code{FALSE}, a new worker process is created using communication over sockets.}

\item{shared}{Logical scalar indicating whether \code{basiliskStart} is allowed 
to load a shared Python instance into the current R process, see \code{\link{getBasiliskShared}}.}

\item{proc}{A process object generated by \code{basiliskStart}.}

\item{fun}{A function to be executed in the \pkg{basilisk} process.
This should return a \dQuote{pure R} object, see details.}

\item{...}{Further arguments to be passed to \code{fun}.}
}
\value{
\code{basiliskStart} returns a process object, the exact nature of which depends on \code{fork} and \code{shared}.
This object should only be used in \code{basiliskRun} and \code{basiliskStop}.

\code{basiliskRun} returns the output of \code{fun(...)}, possibly executed inside the separate process.

\code{basiliskStop} stops the process in \code{proc}.
}
\description{
Creates a \pkg{basilisk} process in which Python operations (via \pkg{reticulate}) 
can be safely performed with the correct versions of Python packages.
}
\details{
These functions ensure that any Python operations in \code{fun} will use the environment specified by \code{envname}.
This avoids version conflicts in the presence of other Python instances or environments loaded by other packages or by the user.
Thus, \pkg{basilisk} clients are not affected by (and if \code{shared=FALSE}, do not affect) the activity of other R packages.

If necessary, objects created in \code{fun} can persist across calls to \code{basiliskRun}, e.g., for file handles.
This requires the use of \code{\link{assign}} with \code{envir} set to \code{\link{findPersistentEnv}} to persist a variable,
and a corresponding \code{\link{get}} to retrieve that object in later calls. 
See Examples for more details.

It is good practice to call \code{basiliskStop} once computation is finished to terminate the process.
Any Python-related operations between \code{basiliskStart} and \code{basiliskStop} should only occur via \code{basiliskRun}.
Calling \pkg{reticulate} functions directly will have unpredictable consequences,
Similarly, it would be unwise to interact with \code{proc} via any function other than the ones listed here.

If \code{proc=NULL} in \code{basiliskRun}, a process will be created and closed automatically.
This may be convenient in functions where persistence is not required.
Note that doing so requires specification of \code{pkgname} and \code{envname}.

If the base Conda installation provided with \pkg{basilisk} satisfies the requirements of the client package, developers can set \code{env=NULL} in this function to use that base installation rather than constructing a separate environment.
}
\section{Choice of process type}{

\itemize{
\item If \code{shared=TRUE} and no Python version has already been loaded, 
\code{basiliskStart} will load Python directly into the R session from the specified environment.
Similarly, if the existing environment is the same as the requested environment, \code{basiliskStart} will use that directly.
This mode is most efficient as it avoids creating any new processes, 
but the use of a shared Python configuration may prevent non-\pkg{basilisk} packages from working correctly in the same session.
\item If \code{fork=TRUE}, no Python version has already been loaded and we are not on Windows, 
\code{basiliskStart} will create a new process by forking.
In the forked process, \code{basiliskStart} will load the specified environment for operations in Python.
This is less efficient as it needs to create a new process 
but it avoids forcing a Python configuration on other packages in the same R session.
\item Otherwise, \code{basiliskStart} will create a parallel socket process containing a separate R session.
In the new process, \code{basiliskStart} will load the specified environment for Python operations.
This is the least efficient as it needs to transfer data over sockets but is guaranteed to work.
}

Developers can control these choices directly by explicitly specifying \code{shared} and \code{fork},
while users can control them indirectly with \code{\link{setBasiliskFork}} and related functions.
}

\section{Constraints on user-defined functions}{

In \code{basiliskRun}, there is no guarantee that \code{fun} has access to \code{basiliskRun}'s calling environment.
This has a number of consequences for the type of code that can be written inside \code{fun}:
\itemize{
\item Functions or variables from non-base R packages used inside \code{fun} should be prefixed with the package namespace, 
or the package itself should be reloaded inside \code{fun}.
\item Any other variables used inside \code{fun} should be explicitly passed as an argument.
Developers should not rely on closures to capture variables in the calling environment of \code{basiliskRun}.
\item Relevant global variables from the calling environment should be explicitly reset inside \code{fun}.
\item Developers should \emph{not} attempt to pass complex objects to memory in or out of \code{fun}.
This mostly refers to objects that contain custom pointers to memory, e.g., file handles, pointers to \pkg{reticulate} objects.
Both the arguments and return values of \code{fun} should be pure R objects.
}
}

\section{Use of lazy installation}{

If the specified \pkg{basilisk} environment is not present and \code{env} is a \linkS4class{BasiliskEnvironment} object, the environment will be created upon first use of \code{basiliskStart}.
If the base Conda installation is not present, it will also be installed upon first use of \code{basiliskStart}.
We do not provide Conda with the \pkg{basilisk} package binaries to avoid portability problems with hard-coded paths (as well as potential licensing issues from redistribution).

By default, both the base conda installation and the environments will be placed in an external user-writable directory defined by \pkg{rappdirs} via \code{\link{getExternalDir}}.
The location of this directory can be changed by setting the \code{BASILISK_EXTERNAL_DIR} environment variable to the desired path.
This may occasionally be necessary if the file path to the default location is too long for Windows, or if the default path has spaces that break the Miniconda/Anaconda installer.

Advanced users may consider setting the environment variable \code{BASILISK_USE_SYSTEM_DIR} to 1 when installing \pkg{basilisk} and its client packages from source.
This will place both the base installation and the environments in the R system directory, which simplifies permission management and avoids duplication in enterprise settings.
}

\section{Persistence of environment variables}{

When \code{shared=TRUE} and if no Python instance has already been loaded into the current R session, 
a side-effect of \code{basiliskStart} is that it will modify a number of environment variables.
This is done to mimic activation of the Conda environment located at \code{env}.
Importantly, old values for these variables will \emph{not} be restored upon \code{basiliskStop}.

This behavior is intentional as (i) the correct use of the Conda-derived Python depends on activation and (ii) the loaded Python persists for the entire R session.
It may not be safe to reset the environment variables and \dQuote{deactivate} the environment while the Conda-derived Python instance is effectively still in use.
(In practice, lack of activation is most problematic on Windows due to its dependence on correct \code{PATH} specification for dynamic linking.)

If persistence is not desirable, users should set \code{shared=FALSE} via \code{\link{setBasiliskShared}}.
This will limit any modifications to the environment variables to a separate R process.
}

\examples{
\dontshow{basilisk.utils::installConda()}

# Creating an environment (note, this is not necessary
# when supplying a BasiliskEnvironment to basiliskStart):
tmploc <- file.path(tempdir(), "my_package_B")
if (!file.exists(tmploc)) {
    setupBasiliskEnv(tmploc, c('pandas=0.25.1',
        "python-dateutil=2.8.0", "pytz=2019.3"))
}

# Pulling out the pandas version, as a demonstration:
cl <- basiliskStart(tmploc)
basiliskRun(proc=cl, function() { 
    X <- reticulate::import("pandas"); X$`__version__` 
})
basiliskStop(cl)

# This happily co-exists with our other environment:
tmploc2 <- file.path(tempdir(), "my_package_C")
if (!file.exists(tmploc2)) {
    setupBasiliskEnv(tmploc2, c('pandas=0.24.1',
        "python-dateutil=2.7.1", "pytz=2018.7"))
}

cl2 <- basiliskStart(tmploc2)
basiliskRun(proc=cl2, function() { 
    X <- reticulate::import("pandas"); X$`__version__` 
})
basiliskStop(cl2)

# Persistence of variables is possible within a Start/Stop pair.
cl <- basiliskStart(tmploc)
basiliskRun(proc=cl, function() {
    assign(x="snake.in.my.shoes", 1, envir=basilisk::findPersistentEnv())
})
basiliskRun(proc=cl, function() {
    get("snake.in.my.shoes", envir=basilisk::findPersistentEnv())
})
basiliskStop(cl)

}
\seealso{
\code{\link{setupBasiliskEnv}}, to set up the conda environments.

\code{\link{getBasiliskFork}} and \code{\link{getBasiliskShared}}, to control various global options.
}
\author{
Aaron Lun
}
