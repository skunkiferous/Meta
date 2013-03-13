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
 * non-primitive, non-Data, property.
 *
 * A type range should not specify any Implementation type.
 *
 * @author monster
 */
public interface TypeRange {

    /** Is the actual instance preserved, implying any child type is accepted? */
    boolean actualInstance();

    /**
     * Does the owner of this property contains/owns the content of the
     * property? Defaults to true.
     */
    boolean contains();

    /**
     * Lists the explicitly accepted children type, of the declared type.
     * An empty list means an exact type match.
     */
    Type[] children();

    /** Is the given type an accepted child type? */
    boolean accept(final Type type);
}
