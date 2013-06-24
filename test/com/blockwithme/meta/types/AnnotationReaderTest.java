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

import java.lang.reflect.Field;
import java.lang.reflect.Method;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;

import junit.framework.TestCase;

import org.reflections.Reflections;

import test.com.blockwithme.meta.A;
import test.com.blockwithme.meta.FieldAnn;
import test.com.blockwithme.meta.MethAnn;
import test.com.blockwithme.meta.MethType;
import test.com.blockwithme.meta.TypeAnn;

import com.blockwithme.meta.annotations.AnnotatedType;
import com.blockwithme.meta.annotations.AnnotationReader;
import com.blockwithme.meta.annotations.impl.AnnotationReaderImpl;

/**
 * @author monster
 *
 */
public class AnnotationReaderTest extends TestCase {

    /**
     * @param name
     */
    public AnnotationReaderTest(final String name) {
        super(name);
    }

    public void testAR() {
        final AnnotationReader ar = new AnnotationReaderImpl(
                new HashMap<String, Object>());
        final List<AnnotatedType> result = ar.read(new Reflections(
                "test.com.blockwithme.meta"), TypeAnn.class, FieldAnn.class,
                MethAnn.class);
        assertEquals(1, result.size());
        final AnnotatedType at = result.get(0);
        assertEquals(at.type, A.class);
        assertTrue(at.constructorAnnotations.isEmpty());

        assertEquals(1, at.typeAnnotations.size());
        final Entry<Class<?>, Map<String, Object>> tae = at.typeAnnotations
                .entrySet().iterator().next();
        assertEquals(TypeAnn.class, tae.getKey());
        assertEquals(Collections.singletonMap("filter", new ArrayList()),
                tae.getValue());

        assertEquals(1, at.fieldAnnotations.size());
        final Entry<Field, Map<Class<?>, Map<String, Object>>> fae = at.fieldAnnotations
                .entrySet().iterator().next();
        assertEquals("CONSTANT", fae.getKey().getName());
        final Map<Class<?>, Map<String, Object>> faev = fae.getValue();
        assertEquals(1, faev.size());
        final Entry<Class<?>, Map<String, Object>> faeve = faev.entrySet()
                .iterator().next();
        assertEquals(FieldAnn.class, faeve.getKey());
        assertEquals(Collections.singletonMap("readOnly", Boolean.TRUE),
                faeve.getValue());

        assertEquals(1, at.methodAnnotations.size());
        final Entry<Method, Map<Class<?>, Map<String, Object>>> mae = at.methodAnnotations
                .entrySet().iterator().next();
        assertEquals("setName", mae.getKey().getName());
        final Map<Class<?>, Map<String, Object>> maev = mae.getValue();
        assertEquals(1, maev.size());
        final Entry<Class<?>, Map<String, Object>> maeve = maev.entrySet()
                .iterator().next();
        assertEquals(MethAnn.class, maeve.getKey());
        assertEquals(Collections.singletonMap("value", MethType.SETTER),
                maeve.getValue());
    }
}
