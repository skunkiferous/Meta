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

Skipped ...

v0.0.4
======

DONE:
=====

TODO:
=====

Add source code generation using Active annotations.

Make sure the tests are updated.

v0.0.5
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

v0.0.6
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

UNPROCESSED:
============

Type instances should offer an array of all Properties in alphabetical order.

Add API to allow Processors to order themselves before or after some other Processor.

Generating a separate Read-Only base interface allows us to reuse it for both immutable types and beans.

Generate a copyInto method?

Generate a compute-a-difference method?

Reset method for Properties (requires use of default).

A Builder is basically just a Bean version of an Immutable, so we really always want both.

Log error if more then one file is used per project during annotation processing.

Refactor annotation processing to move access to internal Xtend API in a separate class.

Cache generated new class names in the "register globals" phase, so the processing only happens once.

Design some functionality to "get all types" at runtime, based on the fact that all dependencies
are "frozen and available" when compiling, and all types in the current project are within the
currently processed file. We might want to generate a list-of-types if the "generate" phase.

We might need to record some meta-information, required for the compilation of dependent projects,
into annotation on the generated/transformed source code.

We should have a "Role" hierarchy (extensible enum or marker interfaces) that "qualifies" the
properties, and can be queried at runtime to drive part of the code generation.

The (original) Meta API IDs should be based on an hexadecimal String, instead of a long.
We could then safely use two bytes per level, at every level, without being limited to 8 bytes.
The Network Coordination should use those String IDs too.

We need a way to make "groups of hierarchies" somehow "linear", so we can define IDs that are
global to the whole group. Maybe we can have a root/primary hierarchy, and the "group ID" is
managed by the root.

How do we solve the "virtually infinite" JRE "hierarchy"?

The Type of a Property can either come form another Hierarchy as Type, or form the same Hierarchy
as Class. The actual Type instance can only be resolved at the Hierarchy construction time.

Complete validation is possible only at Hierarchy construction time.

Allowing the type of a property to become more specific in a sub-type cannot be allowed, as it
would mean the setter of the sub-type accepts only a more specific type, which is not valid in Java.

If for every type of Property (int, Object, ...) the Type instance defined a xxxOffset value,
identifying how many properties of that type have already been defined, then we could have the
global IDs computed as "type.xxxOffset + localID", instead of recorded in each property.

When we add support for Methods, we should have the Properties reference the getter and setter
Methods, instead of using lambdas.

We need a SELF-type. It would be replaced by the type using it. WHen used as parameter, no compile-time check is performed, so a runtime check is needed.

Should the serialisation simulate "composition" instead of "inheritance"? The "wrapper object" could use the "component type" as a key/field-name.

Factories could be implicitly defined by calling a field newXXX, OR we have a @Factory annotation, and all feilds become newXXX. One Factory per package would be simpler.

If we limit the bean properties to primitives, Beans, and a small set of pre-defined types, we could generate a "tree size" for each Type. But restricting non-bean types to a fixed list is not good.

We could enable the creation and application of "patches", by serializing the "selected" (dirty) properties only.

We could allow the definition of "real" constants in the beans, by having the fields (which are constants anyway) have a specified value. Could the constant values be overwritten in subtypes? This would require the constants to be turned to "getters" that return a constant.

For each "parent", we should compute the number of properties. The parent with the greatest number of properties should be used as base-class.

Apache Common Lang defines mutable primitive types. Maybe those could be used for "primitive collections"?

We should add "implicit extension", called "retrofitting", to our feature-set. This would allow forcing all instances of type X in the application to also implement type Y, such that this relationship is defined on extended type, and not on the extending type.

An alternative to bytecode manipulation to implement retrofitting is to use the "extender pattern", where composition adds the additional retrofitted data. We could use either an extension array, or a linked list, of extensions, or just one mutiple-inherited extension.

Beans could offer a "map view" of their properties. Any code that "knows" about the Properties does not need to use a map view, so we should use Strings as the map key.

If we have "read-only", "computed" properties, we need to have new property lists, which contains only "real" properties.

If the API type of a property is NOT a bean, then we should check that no bean can be set in this property.

If we force the use of a "unique prefix" to prevent name clashes, this prefix should represent the "Maven group-ID", rather then then Maven artifact-ID or the hierarchy-ID. Group-IDs are orthogonal to hierarchies.

Hierarchies should take the group prefix as parameter and validate all "names".

Could we have one "stateful" interceptor per reactor? Immutable "traveling" beans would use a stateless global interceptor?

All "convertible" should be immutable.

"Accepted types" are then primitives, immutable, array/collection, and beans.

We should allow the definition of virtual properties just by annotating the interface field with an annotation that defines the getter and setter implementations as Strings.

Bean properties should have their own property list in the Type.

We need a method in the Bean that takes some kind of "filter", and returns all the "matching properties", and some annotation that allows generating a "getter" returning the "matching properties" based on some pre-defined filter.

Entities should be Blades.

We also need an "invalid" flag. I'm not sure yet how the propagation should work, but the flag would indicate that the bean *cannot be serialized/saved*, and so any parent cannot be serialized either.

I need a better name for my "Beans"; they aren't really beans (like EJB beans). Maybe I can use the term "trait", in which case I could rename the whole API to "Traitor".

Check that the immutable flag is respected everywhere.

Should setting the immutable flag to true cause a propagation to all children?

The bean reference to it's parent should also include either the property, or the collection index or the map key.

Can the parent of an immutable bean change? If we also store the parent property and optional index/key, we can't even mutate it atomically. So should we require from immutable that their parent be either nul or also immutable?

Using immutabiltiy propagation would ensure that "Requests" be thread-safe.

Instead of defining simply "properties" and "constants", we should switch to defining every property to have a "scope", where "instance scope" is the default scope, and "constant" is just one possible scope.

"Exact type mathcing" (for collections and properties) should use the Type of a bean, instad of it's class (which is used for non-beans).

The "create" method for collection properties should be called "get", with the normal get being called "getRaw".

Add an "empty arrray" instance to every type instance.

The part of the bean processor that generates the property code should be separated into it's own class, so that property generation become customizable.

