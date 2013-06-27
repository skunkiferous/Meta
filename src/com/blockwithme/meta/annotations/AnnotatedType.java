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
import java.util.Map;

/**
 * @author monster
 *
 */
public interface AnnotatedType {

    /** Returns the annotated type itself. */
    public Class<?> getType();

    /** Returns the type annotation data. */
    public Map<Class<?>, PropMap> getTypeData();

    /** Adds a type annotation. */
    public AnnotatedType addTypeAnnotation(final Class<?> annotation,
            final PropMap data);

    /** Returns all the registered methods. */
    public Method[] getMethods();

    /** Returns the Method annotation data. */
    public Map<Class<?>, PropMap> getMethodData(final Method method);

    /** Adds a Method annotation. */
    public AnnotatedType addMethodAnnotation(final Method method,
            final Class<?> annotation, final PropMap data);

    /** Returns all the registered Constructors. */
    @SuppressWarnings("rawtypes")
    public Constructor[] getConstructors();

    /** Returns the Constructor annotation data. */
    public Map<Class<?>, PropMap> getConstructorData(
            @SuppressWarnings("rawtypes") final Constructor constructor);

    /** Adds a Constructor annotation. */
    public AnnotatedType addConstructorAnnotation(
            @SuppressWarnings("rawtypes") final Constructor constructor,
            final Class<?> annotation, final PropMap data);

    /** Returns all the registered Fields. */
    public Field[] getFields();

    /** Returns the Field annotation data. */
    public Map<Class<?>, PropMap> getFieldData(final Field field);

    /** Adds a Field annotation. */
    public AnnotatedType addFieldAnnotation(final Field field,
            final Class<?> annotation, final PropMap data);

}