Meta
====

The second generation, XTend-based, Meta API for Types, Networks, ...


RELEASES:
=========

v0.0.2 (2013-12-26)
===================

An optional interface for "typed" instances could allow retrieving
    the Type of an object without having to recourse to hashing.

Replace all "parent" volatile fields wit a single generic parent field in parent of MetaBase.

Packages should be created explicitly, to allow them to be extensible.
They should receive the Type instances, the way Type receives the Property instances.

Hierarchy should receive the Packages instances, the way Type receives the Property instances.

We should move to context-aware converters (Context would be owning object)

All Setters should return the instance, so we can use them for immutable types.

Move to Functors for getters and setters.

Make sure the tests are updated.

RELEASE PLAN:
=============

v0.0.3
======

DONE:
=====

TODO:
=====

Add source code generation using Active annotations.

Make sure the tests are updated.

v0.0.4
======

DONE:
=====

TODO:
=====

Add Interfaces for all the meta-types

We need to detect if a property/method/type/package was "forgotten"
at the creation of it's parent.

Add PrimitiveProperty.getAsDouble

Define a EnumProperty interface, extending the to-be-defined Property interfaces
to allow a Enum property to be based on either byte, char, or String.

We need some kind of visitor pattern over the Meta-classes

Type creation should support parameters as well. Or should we
instead define Constructor objects, like the Properties? Constructors
are then a special case of Methods.

What about generic Builders for immutable types?
Do we need them if we have Constructor objects? Or the other way around?

Add IsTrue.isTrue(*)

Add Generics (double[]+Object[] == everything)

---Add Minimal (Double+Object) Functors---

Add Prop.getGeneric

32-bit slot property index (where long and double take two slots)

Add immutable flag to Type

We probably want readOnly/writeOnly flags for Properties

Allow the creation of converters from Functors.

Make sure the tests are updated.

v0.0.5
======

DONE:
=====

TODO:
=====

Reduce Potential for circular dependency, by having the data-type of
Properties being initialized once the Hierarchy is "ready".

The data-type of properties can either be a Type of another hierarchy,
or a Class of the same hierarchy.

Add static flag to Properties, and create static subclasses, that do not
need an instance parameter in the getter/setter. Static properties do not
get serialized. Static properties should have their own "ID space".

Should we add support for Google Guice? Can Context/Scope simply be defined
as "related data" that cannot simply be accessed through navigating properties?

Add support for Object-Object converter, with reversibility

String properties

Long-As-Object properties

String convertible properties (uses Object-Object converter)

Add Scala-style Symbols (must NOT be user-creatable)
Symbols probably need their own Hierarchy.

Array / Collection / Map properties

Add meta-property auto-initializers
(must somehow make sure all things registered both before and after
the auto-initializers themselves are registered all get a value)
Use "HierarchyListener" for that

Make sure the tests are updated.

LATER
=====

DONE:
=====

TODO:
=====

Write some usable documentation, to help people get started.

Write high-level design goals.

Use the Hierarchy-Builder as a "? extends MetaBase" Factory, allowing
the concrete subclass used to be configurable, despite the static
initialization.

Compound-Type (Composition): Compound types could be implemented,
by using an array in each compound type instance, which would map
a global property ID (primitive/object) to a compound type property ID.

Review and integrate missing concepts from original Meta project.

Could be build a generic serializer on the Meta-API?

Are Properties just a special case of Context-Aware Converters?

Add "generic Enums" based on the Symbols

Add "Methods" (?)

Support fake base-classes (Make Boolean a sub-type of Number)

Do we even care about "non-static" Types?

Add Read-only properties for Java-Lang types

Add support for annotations (in some cross-platform way)

The Meta-API must also support Exceptions types

Make sure the tests are updated.

