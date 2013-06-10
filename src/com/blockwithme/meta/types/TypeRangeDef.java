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
package com.blockwithme.meta.types;

/**
 * The type range defines the range of possible types accepted by a
 * non-primitive, non-Data, property. It defaults to all children types of
 * the declared type, as is the Java convention, when not specified.
 *
 * A type range should not specify any Implementation type.
 *
 * If both inclusions and exclusions are specified, the exclusions win.
 *
 * @author monster
 */
public @interface TypeRangeDef {

    /** Is the actual instance preserved, implying any child type is accepted? */
    boolean actualInstance() default false;

    /** Is only the the declared type accepted, and only the data value preserved? */
    boolean exact() default false;

    /**
     * Does the owner of this property contains/owns the content of the
     * property? Defaults to true.
     */
    boolean contains() default true;

    /**
     * Lists the explicitly accepted children type, of the declared type.
     * An empty list does not imply an exact type match.
     */
    Class<?>[] children() default {};

    /**
     * Defines the implicitly accepted children types, of the declared type,
     * through custom filters.
     * An empty list does not imply an exact type match.
     */
    Class<? extends TypeFilter>[] childrenFilters() default {};

    /**
     * Additional type restrictions, which limit the types of the instances,
     * by specifying that some other type cannot be accepted.
     */
    Class<?>[] excludes() default {};

    /** Implicit type exclusion, through custom filters. */
    Class<? extends TypeFilter>[] excludeFilters() default {};
}
