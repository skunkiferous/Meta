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
package com.blockwithme.meta.annotations.impl;

import java.lang.reflect.Constructor;
import java.lang.reflect.Field;
import java.lang.reflect.Method;
import java.util.HashMap;
import java.util.Map;
import java.util.Objects;

import com.blockwithme.meta.annotations.AnnotatedType;
import com.blockwithme.meta.annotations.PropMap;

/**
 * Implements an annotated type representation. The logic that actually
 * generates the data comes from AnnotationReaderImpl.
 *
 * @author monster
 */
public class AnnotatedTypeImpl implements AnnotatedType {
    /** The annotated type itself. */
    private final Class<?> type;

    /**
     * The type annotations.
     *
     * The map key is the annotation type, and the value is a map of (possibly
     * converted) properties.
     */
    private final Map<Class<?>, PropMap> typeAnnotations = new HashMap<>();

    /**
     * The method annotations.
     *
     * Maps methods (key) to their annotations (map).
     *
     * The map key is the annotation type, and the value is a map of (possibly
     * converted) properties.
     */
    private final Map<Method, Map<Class<?>, PropMap>> methodAnnotations = new HashMap<>();

    /**
     * The constructor annotations.
     *
     * Maps constructor (key) to their annotations (map).
     *
     * The map key is the annotation type, and the value is a map of (possibly
     * converted) properties.
     */
    private final Map<Constructor<?>, Map<Class<?>, PropMap>> constructorAnnotations = new HashMap<>();

    /**
     * The field annotations.
     *
     * Maps methods (key) to their annotations (map).
     *
     * The map key is the annotation type, and the value is a map of (possibly
     * converted) properties.
     */
    private final Map<Field, Map<Class<?>, PropMap>> fieldAnnotations = new HashMap<>();

    /** Creates an AnnotatedType. */
    public AnnotatedTypeImpl(final Class<?> theType) {
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

    /* (non-Javadoc)
     * @see com.blockwithme.meta.annotations.impl.AnnotatedType#getType()
     */
    @Override
    public Class<?> getType() {
        return type;
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.annotations.impl.AnnotatedType#getTypeData()
     */
    @Override
    public Map<Class<?>, PropMap> getTypeData() {
        return typeAnnotations;
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.annotations.impl.AnnotatedType#addTypeAnnotation(java.lang.Class, java.util.Map)
     */
    @Override
    public AnnotatedType addTypeAnnotation(final Class<?> annotation,
            final PropMap data) {
        final PropMap m = typeAnnotations.get(annotation);
        if (m == null) {
            typeAnnotations.put(annotation, data);
        } else {
            m.putAll(data);
        }
        return this;
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.annotations.impl.AnnotatedType#getMethods()
     */
    @Override
    public Method[] getMethods() {
        return methodAnnotations.keySet().toArray(
                new Method[methodAnnotations.size()]);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.annotations.impl.AnnotatedType#getMethodData(java.lang.reflect.Method)
     */
    @Override
    public Map<Class<?>, PropMap> getMethodData(final Method method) {
        Map<Class<?>, PropMap> m = methodAnnotations.get(method);
        if (m == null) {
            m = new HashMap<>();
            methodAnnotations.put(method, m);
        }
        return m;
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.annotations.impl.AnnotatedType#addMethodAnnotation(java.lang.reflect.Method, java.lang.Class, java.util.Map)
     */
    @Override
    public AnnotatedType addMethodAnnotation(final Method method,
            final Class<?> annotation, final PropMap data) {
        getMethodData(method).put(annotation, data);
        return this;
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.annotations.impl.AnnotatedType#getConstructors()
     */
    @Override
    @SuppressWarnings("rawtypes")
    public Constructor[] getConstructors() {
        return constructorAnnotations.keySet().toArray(
                new Constructor[constructorAnnotations.size()]);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.annotations.impl.AnnotatedType#getConstructorData(java.lang.reflect.Constructor)
     */
    @Override
    public Map<Class<?>, PropMap> getConstructorData(
            @SuppressWarnings("rawtypes") final Constructor constructor) {
        Map<Class<?>, PropMap> m = constructorAnnotations.get(constructor);
        if (m == null) {
            m = new HashMap<>();
            constructorAnnotations.put(constructor, m);
        }
        return m;
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.annotations.impl.AnnotatedType#addConstructorAnnotation(java.lang.reflect.Constructor, java.lang.Class, java.util.Map)
     */
    @Override
    public AnnotatedType addConstructorAnnotation(
            @SuppressWarnings("rawtypes") final Constructor constructor,
            final Class<?> annotation, final PropMap data) {
        getConstructorData(constructor).put(annotation, data);
        return this;
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.annotations.impl.AnnotatedType#getFields()
     */
    @Override
    public Field[] getFields() {
        return fieldAnnotations.keySet().toArray(
                new Field[fieldAnnotations.size()]);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.annotations.impl.AnnotatedType#getFieldData(java.lang.reflect.Field)
     */
    @Override
    public Map<Class<?>, PropMap> getFieldData(final Field field) {
        Map<Class<?>, PropMap> m = fieldAnnotations.get(field);
        if (m == null) {
            m = new HashMap<>();
            fieldAnnotations.put(field, m);
        }
        return m;
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.annotations.impl.AnnotatedType#addFieldAnnotation(java.lang.reflect.Field, java.lang.Class, java.util.Map)
     */
    @Override
    public AnnotatedType addFieldAnnotation(final Field field,
            final Class<?> annotation, final PropMap data) {
        getFieldData(field).put(annotation, data);
        return this;
    }
}
