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

import java.lang.annotation.Annotation;
import java.lang.reflect.Constructor;
import java.lang.reflect.Field;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.lang.reflect.Modifier;
import java.lang.reflect.Proxy;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Objects;

import org.reflections.Reflections;

import com.blockwithme.meta.annotations.AnnotatedType;
import com.blockwithme.meta.annotations.AnnotationReader;
import com.blockwithme.meta.annotations.Converter;
import com.blockwithme.meta.annotations.Instantiate;
import com.blockwithme.meta.annotations.PostProcessor;

/**
 * An AnnotationReader implementation.
 *
 * @author monster
 */
public class AnnotationReaderImpl implements AnnotationReader {
    /** All the PostProcessors. */
    private final List<PostProcessor> postProcessors = new ArrayList<>();

    /** All the property converters. */
    @SuppressWarnings("rawtypes")
    private final Map<Map<Class<?>, String>, Converter> propertyConverters = new HashMap<>();

    /** All the value converters. */
    @SuppressWarnings("rawtypes")
    private final Map<Map<Class<?>, Class<?>>, Converter> valueConverters = new HashMap<>();

    /** All the annotation methods. */
    private final Map<Class<?>, Method[]> annotationMethods = new HashMap<>();

    /** The context. */
    private final Map<String, Object> context;

    /**
     *
     */
    @SuppressWarnings("unchecked")
    public AnnotationReaderImpl(final Map<String, Object> context) {
        this.context = context;
        @SuppressWarnings("rawtypes")
        final Instantiator converter = new Instantiator<>();
        withValueConverter(Instantiate.class, String.class, converter);
        withValueConverter(Instantiate.class, String[].class, converter);
        withValueConverter(Instantiate.class, Class.class, converter);
        withValueConverter(Instantiate.class, Class[].class, converter);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.annotations.AnnotationReader#withPropertyConverter(java.lang.Class, java.lang.String, com.blockwithme.meta.annotations.Converter)
     */
    @SuppressWarnings({ "unchecked", "rawtypes" })
    @Override
    public <ANNOTATION> AnnotationReader withPropertyConverter(
            final Class<ANNOTATION> annotationType, final String property,
            final Converter<?, ANNOTATION, ?> converter) {
        final Map key = Collections.singletonMap(
                Objects.requireNonNull(annotationType, "annotationType"),
                Objects.requireNonNull(property, "property"));
        propertyConverters.put(key,
                Objects.requireNonNull(converter, "converter"));
        return this;
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.annotations.AnnotationReader#withValueConverter(java.lang.Class, java.lang.Class, com.blockwithme.meta.annotations.Converter)
     */
    @SuppressWarnings({ "unchecked", "rawtypes" })
    @Override
    public <ANNOTATION, VALUE> AnnotationReader withValueConverter(
            final Class<ANNOTATION> annotationType,
            final Class<VALUE> valueType, final Converter<VALUE, ?, ?> converter) {
        final Map key = Collections.singletonMap(
                Objects.requireNonNull(annotationType, "annotationType"),
                Objects.requireNonNull(valueType, "valueType"));
        valueConverters
                .put(key, Objects.requireNonNull(converter, "converter"));
        return this;
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.annotations.AnnotationReader#withPostProcessor(com.blockwithme.meta.annotations.PostProcessor)
     */
    @Override
    public AnnotationReader withPostProcessor(final PostProcessor postProcessor) {
        postProcessors.add(Objects.requireNonNull(postProcessor));
        return this;
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.annotations.AnnotationReader#read(org.reflections.Reflections, java.lang.Class<? extends java.lang.annotation.Annotation>[])
     */
    @SuppressWarnings("unchecked")
    @Override
    public List<AnnotatedType> read(final Reflections reflections,
            final Class<? extends Annotation>... annotations) {
        final List<AnnotatedType> result = new ArrayList<>();
        final HashSet<Class<?>> types = new HashSet<>();
        for (final Class<? extends Annotation> annotation : annotations) {
            types.addAll(reflections.getTypesAnnotatedWith(annotation));
            for (final Field field : reflections
                    .getFieldsAnnotatedWith(annotation)) {
                types.add(field.getDeclaringClass());
            }
            for (final Method method : reflections
                    .getMethodsAnnotatedWith(annotation)) {
                types.add(method.getDeclaringClass());
            }
            for (final Constructor<?> constructor : reflections
                    .getConstructorsAnnotatedWith(annotation)) {
                types.add(constructor.getDeclaringClass());
            }
        }
        for (final Class<?> type : types) {
            result.add(read(type));
        }
        return result;
    }

    /** Returns all the getters for the given annotation. */
    private Method[] findGetters(final Class<?> annotation) {
        Method[] result = annotationMethods.get(annotation);
        if (result == null) {
            final List<Method> list = new ArrayList<>();
            for (final Method m : annotation.getDeclaredMethods()) {
                if (!m.getName().equals("annotationType")
                        && !m.getName().equals("toString")
                        && !m.getName().equals("hashCode")
                        && (m.getParameterTypes().length == 0)
                        && !m.isSynthetic()
                        && Modifier.isPublic(m.getModifiers())) {
                    list.add(m);
                }
            }
//            System.out.println("findGetters(" + annotation + ")=" + list);
            result = list.toArray(new Method[list.size()]);
            annotationMethods.put(annotation, result);
        }
        return result;
    }

    /** Process an annotation. */
    @SuppressWarnings({ "rawtypes", "unchecked" })
    private Map<String, Object> processAnnotation(
            final AnnotatedType annotatedType, final Annotation annotation) {
        final Class<?> annotationType = unproxy(annotation.getClass());
        final Map<String, Object> result = new HashMap<>();
        for (final Method getter : findGetters(annotationType)) {
            final String property = getter.getName();
            // Read value
            Object value = null;
            try {
                value = getter.invoke(annotation);
            } catch (IllegalAccessException | IllegalArgumentException
                    | InvocationTargetException e) {
                e.printStackTrace();
            }
            // Process value
            Converter converter = propertyConverters.get(Collections
                    .singletonMap(annotationType, property));
            if (converter != null) {
                value = converter.convert(context, annotatedType, annotation,
                        property, value);
            } else {
                for (final Annotation getterAnnotation : getter
                        .getAnnotations()) {
                    converter = valueConverters.get(Collections.singletonMap(
                            unproxy(getterAnnotation.getClass()),
                            getter.getReturnType()));
                    if (converter != null) {
                        value = converter.convert(context, annotatedType,
                                annotation, property, value);
                    }
                }
            }
            result.put(property, value);
        }
        return result;
    }

    private Class<?> unproxy(final Class<?> maybeProxy) {
        if (Proxy.isProxyClass(maybeProxy)) {
            final Class<?>[] interfaces = maybeProxy.getInterfaces();
            if (interfaces.length == 1) {
                return interfaces[0];
            } else if (interfaces.length > 1) {
                System.out.println("Too many interfaces for: " + maybeProxy
                        + " " + Arrays.asList(interfaces));
            }
        }
        return maybeProxy;
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.annotations.AnnotationReader#read(java.lang.Class)
     */
    @Override
    public AnnotatedType read(final Class<?> type) {
        final AnnotatedType result = new AnnotatedType(type);
        for (final Annotation annotation : type.getAnnotations()) {
            result.typeAnnotations.put(unproxy(annotation.getClass()),
                    processAnnotation(result, annotation));
        }
        Map<Class<?>, Map<String, Object>> map = null;
        for (final Method method : type.getMethods()) {
            if (map == null) {
                map = new HashMap<>();
            }
            for (final Annotation annotation : method.getAnnotations()) {
                map.put(unproxy(annotation.getClass()),
                        processAnnotation(result, annotation));
            }
            if (!map.isEmpty()) {
                result.methodAnnotations.put(method, map);
                map = null;
            }
        }
        for (final Constructor<?> constructor : type.getConstructors()) {
            if (map == null) {
                map = new HashMap<>();
            }
            for (final Annotation annotation : constructor.getAnnotations()) {
                map.put(unproxy(annotation.getClass()),
                        processAnnotation(result, annotation));
            }
            if (!map.isEmpty()) {
                result.constructorAnnotations.put(constructor, map);
                map = null;
            }
        }
        for (final Field field : type.getFields()) {
            if (map == null) {
                map = new HashMap<>();
            }
            for (final Annotation annotation : field.getAnnotations()) {
                map.put(unproxy(annotation.getClass()),
                        processAnnotation(result, annotation));
            }
            if (!map.isEmpty()) {
                result.fieldAnnotations.put(field, map);
                map = null;
            }
        }
        for (final PostProcessor postProcessor : postProcessors) {
            postProcessor.process(result);
        }
        System.out.println("read(" + type + ")=" + result);
        return result;
    }
}
