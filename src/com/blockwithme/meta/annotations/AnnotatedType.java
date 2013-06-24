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
package com.blockwithme.meta.annotations;

import java.lang.reflect.Constructor;
import java.lang.reflect.Field;
import java.lang.reflect.Method;
import java.util.HashMap;
import java.util.Map;
import java.util.Objects;

/**
 * Represents an annotated type.
 *
 * @author monster
 */
public class AnnotatedType {
    /** The annotated type itself. */
    public final Class<?> type;

    /**
     * The type annotations.
     *
     * The map key is the annotation type, and the value is a map of (possibly
     * converted) properties.
     */
    public final Map<Class<?>, Map<String, Object>> typeAnnotations = new HashMap<>();

    /**
     * The method annotations.
     *
     * Maps methods (key) to their annotations (map).
     *
     * The map key is the annotation type, and the value is a map of (possibly
     * converted) properties.
     */
    public final Map<Method, Map<Class<?>, Map<String, Object>>> methodAnnotations = new HashMap<>();

    /**
     * The constructor annotations.
     *
     * Maps constructor (key) to their annotations (map).
     *
     * The map key is the annotation type, and the value is a map of (possibly
     * converted) properties.
     */
    public final Map<Constructor<?>, Map<Class<?>, Map<String, Object>>> constructorAnnotations = new HashMap<>();

    /**
     * The field annotations.
     *
     * Maps methods (key) to their annotations (map).
     *
     * The map key is the annotation type, and the value is a map of (possibly
     * converted) properties.
     */
    public final Map<Field, Map<Class<?>, Map<String, Object>>> fieldAnnotations = new HashMap<>();

    /** Creates an AnnotatedType. */
    public AnnotatedType(final Class<?> theType) {
        type = Objects.requireNonNull(theType);
    }

    /** Dumps all the recorded data. */
    @Override
    public String toString() {
        final StringBuilder buf = new StringBuilder();
        buf.append("AnnotatedType(type=").append(type.getName());
        buf.append(",\ntypeAnnotations=").append(typeAnnotations);
        buf.append(",\nconstructorAnnotations=").append(constructorAnnotations);
        buf.append(",\nmethodAnnotations=").append(methodAnnotations);
        buf.append(",\nfieldAnnotations=").append(fieldAnnotations);
        buf.append(")");
        return buf.toString();
    }
}
