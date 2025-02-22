#lang scribble/manual
@require[@for-label[racket/base
                    ffi/unsafe
                    ffi/unsafe/define]]

@title{Unsafe Bindings}
@defmodule[vulkan/unsafe]

The unsafe module is exactly as the name implies. @bold{Use at your
own risk.}

@racketmodname[vulkan/unsafe] provides over 2200 bindings representing
all supported and deprecated Vulkan structs, unions, enumerated types,
constants and functions across all platforms, extensions, and
published Vulkan API verions. There are few protections against
misuse. This means that @italic{mistakes risk undefined behavior, race
conditions, and memory leaks, making this module a poor choice for
anyone seeking clear error messages, strong validation, and concise
code.}

The module is designed such that you can closely mirror an equivalent
C program. This makes it easier to port existing Vulkan programs to
Racket. You should only use this module to write your own
abstractions in terms of @racketmodname[ffi/unsafe], or to study
Vulkan via Racket while following along with tutorials or
documentation written for C or C++.

It is possible to write cross-platform and backwards-compatible Vulkan
applications with this module, but you are responsible for detecting
the platform and using APIs from the correct version. This module is
simply a dump of all things Vulkan into Racket. So, when you
@racket[require] this module, you may assume that all Vulkan
identifiers defined in the specification for the core API and all
extensions are provided in your dependent module's namespace.

The translation from C to Racket is not 1-to-1. Observe the following:

@margin-note{To repeat, the interface is unstable and these items are subject to change.}
@itemlist[
@item{All identifiers acting as C types are prefixed with an underscore. So, the C type @tt{VkInstance} is bound to the @tt{_VkInstance} identifier in Racket.}
@item{All enumerants are available as symbols and identifiers. The Racket identifier @tt{VK_SUCCESS} binds to the Racket value equivalent of @tt{VK_SUCCESS} In Vulkan. However, symbols like @racket['VK_SUCCESS] are available for FFI wrapper procedures that translate @racket[_enum] or @racket[_bitmask] values.}
@item{API constants that are NOT from enumerated types are identifiers bound to a Racket value. e.g. @tt{VK_API_VERSION_1_1}.}
@item{All Vulkan functions are provided as Racket procedures with an identifier matching the name. e.g. The @tt{vkCreateInstance} C function is a Racket procedure also named @tt{vkCreateInstance}.}
@item{A Racket procedure's presence is not a guarentee that the associated C function is available as an object in the system library. If you call @tt{vkCreateAndroidSurfaceKHR} on a non-Android platform, the C function will not be found.}
@item{Unions are generated with accessor procedures that wrap @racket[union-ref]. So if a union @tt{U} has a member named @tt{floats}, you can access all Racket values converted from that union using @tt{(U-floats union-val)}.}
@item{Structs are created using @racket[define-cstruct], meaning that all bindings generated from that form exist for every Vulkan structure (e.g. @tt{_VkImageCreateInfo-pointer/null}).}
@item{As an aid, all functions that return a @tt{VkResult} are automatically
checked. Any return value that is not @tt{VK_SUCCESS} translates to a raised
@racket[exn:fail].}
]
