/*
 * Copyright (C) 2013 Sebastien Diot.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package com.blockwithme.meta.types.annotations;

import java.lang.annotation.Documented;
import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

import com.blockwithme.meta.annotations.Instantiate;
import com.blockwithme.meta.types.Access;
import com.blockwithme.meta.types.Kind;
import com.blockwithme.meta.types.TypeFilter;

/**
 * A TypeDef describes the type it annotates, to allow schema validation.
 * It can be used on any kind of Java Class.
 *
 * Java types should be used to represent any external resource, to allow
 * a uniform mean of classification of all resources.
 *
 * By default, types inheriting from Root types, or Specialization, are
 * themselves Specialization.
 *
 * By default, types inheriting from Data types, are themselves Data types.
 *
 * Types inheriting from Implementation types, must be themselves
 * Implementation types.
 *
 * Trait types do not put any limitation, or implication, on types that inherit
 * from them. Therefore a child Trait must itself specify that it is a Trait
 * type, or something else.
 *
 * Third-party types, including the JDK types, can also be classified by
 * registering them explicitly with the type registry.
 *
 * A type system can only be validated, once all types belonging to it are
 * known. This implies that all types used anywhere in the code must be
 * declared explicitly, even the JDK types. Once the full security system is in
 * place, it will not be possible to load a class, unless it has been
 * classified. Therefore using filters is adequate, because once all the types
 * are known for the system, it can be validated as a whole, and for every
 * type, the concrete list of children and parent types can be computed.
 *
 * <code>@TypeDef</code> is explicitly not inheritable.
 *
 * @author monster
 */
@Target(ElementType.TYPE)
@Retention(RetentionPolicy.RUNTIME)
@Documented
public @interface Type {
    /** The kind of type, that this class/interface/enum is. */
    Kind kind() default Kind.Specialization;

    /** The access-level. */
    Access access() default Access.Default;

    /**
     * The types that are implicitly also implemented by this type. This is
     * rarely needed, as inheritance is normally sufficient to specify all the
     * super types. If used, the instance must be converted to the appropriate
     * parent type, when access to the parent types interface needed.
     */
    Class<?>[] parents() default {};

    /** Implicit parents definition, through custom filters. */
    @Instantiate
    Class<? extends TypeFilter>[] parentFilters() default {};

    /**
     * Similar to parents, but backwards. It means that all instances of the
     * children types, will also be instances of this type. Think of it as a
     * kind of "base class injection".
     */
    Class<?>[] children() default {};

    /** Implicit children definition, through custom filters. */
    @Instantiate
    Class<? extends TypeFilter>[] childrenFilters() default {};

    /**
     * Additional type restrictions, which limit the sub-types and instances,
     * by specifying that some other type cannot be implemented at the same
     * time as this type.
     */
    Class<?>[] excludes() default {};

    /** Implicit type exclusion, through custom filters. */
    @Instantiate
    Class<? extends TypeFilter>[] excludeFilters() default {};

    /**
     * The Type's Domain. It is implicitly defined as the Root type, if this
     * type is a Root type, or the child of a Root type. For Traits and Data
     * types, which are not explicitly children of a Root type, this can be
     * used to associate the type with a Domain. Otherwise, the type will not
     * be Domain-specific.
     */
    Class<?> domain() default Object.class;

    /** What kinds of persistence are allowed. */
    String[] persistence() default {};
}
