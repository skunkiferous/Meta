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
package com.blockwithme.meta.infrastructure.impl;

import java.util.Arrays;
import java.util.Comparator;
import java.util.HashMap;
import java.util.IdentityHashMap;
import java.util.Map;
import java.util.Objects;
import java.util.TreeMap;

import com.blockwithme.meta.Configurable;
import com.blockwithme.meta.infrastructure.AppState;
import com.blockwithme.meta.infrastructure.Application;
import com.blockwithme.meta.types.Bundle;

/**
 * @author monster
 *
 */
public class ApplicationImpl implements Application {

    private final String name;

    private final boolean javaApp;

    private final boolean distributed;

    private final Comparator<Bundle> cmp = new Comparator<Bundle>() {
        @Override
        public int compare(final Bundle o1, final Bundle o2) {
            if (o1 == o2) {
                return 0;
            }
            final int d1 = distanceFromRoot(o1);
            final int d2 = distanceFromRoot(o2);
            if (d1 != d2) {
                return d1 - d2;
            }
            // TODO
            return o1.name().compareTo(o2.name());
        }
    };

    private final AppState appState;

    /** The current application time. */
    private volatile long time;

    /** The bundle. */
    private volatile Bundle bundle;

    /** All the state of this definition. */
    private final IdentityHashMap<Configurable<?>, TreeMap<String, Map<Bundle, TreeMap<Long, Object>>>> state = new IdentityHashMap<>();

    /**
     *
     */
    public ApplicationImpl(final String name, final boolean javaApp,
            final boolean distributed) {
        appState = new AppStateImpl(this);
        this.name = Objects.requireNonNull(name);
        this.javaApp = javaApp;
        this.distributed = distributed;
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.Definition#name()
     */
    @Override
    public String name() {
        return name;
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.Configurable#properties()
     */
    @Override
    public String[] properties() {
        return appState().properties();
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.Configurable#getProperty(java.lang.Long, java.lang.String)
     */
    @Override
    public Object getProperty(final Long time, final String name) {
        return appState().getProperty(time, name);
    }

    /* (non-Javadoc)
     * @see java.lang.Comparable#compareTo(java.lang.Object)
     */
    @Override
    public int compareTo(final Application o) {
        return name.compareTo(o.name());
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.infrastructure.Application#bundle()
     */
    @Override
    public Bundle bundle() {
        return Objects.requireNonNull(bundle);
    }

    public ApplicationImpl setBundle(final Bundle theBundle) {
        bundle = Objects.requireNonNull(theBundle);
        return this;
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.infrastructure.Application#time()
     */
    @Override
    public long time() {
        return time;
    }

    public ApplicationImpl setTime(final long theTime) {
        time = theTime;
        return this;
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.infrastructure.Application#bundleComparator()
     */
    @Override
    public Comparator<Bundle> bundleComparator() {
        return cmp;
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.infrastructure.Application#distributed()
     */
    @Override
    public boolean distributed() {
        return distributed;
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.infrastructure.Application#javaApp()
     */
    @Override
    public boolean javaApp() {
        return javaApp;
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.infrastructure.Application#appState()
     */
    @Override
    public AppState appState() {
        return appState;
    }

    /** Allows adding empty property names slots at the end of the array. */
    @Override
    public String[] properties(final Configurable<?> cfg, final int freeslots) {
        synchronized (state) {
            final TreeMap<String, Map<Bundle, TreeMap<Long, Object>>> map = state
                    .get(cfg);
            if (map == null) {
                return new String[0];
            }
            return map.keySet().toArray(new String[map.size() + freeslots]);
        }
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.Definition#getProperty(java.lang.String)
     */
    @Override
    public Object getProperty(final Configurable<?> cfg, final Long time,
            final String name) {
        synchronized (state) {
            final TreeMap<String, Map<Bundle, TreeMap<Long, Object>>> map = state
                    .get(cfg);
            if (map == null) {
                return null;
            }
            final Map<Bundle, TreeMap<Long, Object>> bundlesMap = map.get(name);
            if (bundlesMap == null) {
                return null;
            }
            final Bundle[] bundles = bundlesMap.keySet().toArray(
                    new Bundle[bundlesMap.size()]);
            Arrays.sort(bundles, bundleComparator());
            final TreeMap<Long, Object> values = bundlesMap.get(bundles[0]);
            Object result = null;
            final long checkTime = (time == null) ? time() : time;
            for (final Long t : values.keySet()) {
                if (t.longValue() <= checkTime) {
                    result = values.get(t);
                }
            }
            return result;
        }
    }

    /** Sets a property. */
    @Override
    public Application setProperty(final Configurable<?> cfg,
            final Bundle bundle, final long time, final String name,
            final Object value) {
        synchronized (state) {
            TreeMap<String, Map<Bundle, TreeMap<Long, Object>>> map = state
                    .get(cfg);
            if (map == null) {
                map = new TreeMap<>();
                state.put(cfg, map);
            }
            Map<Bundle, TreeMap<Long, Object>> bundlesMap = map.get(name);
            if (bundlesMap == null) {
                bundlesMap = new HashMap<Bundle, TreeMap<Long, Object>>();
                map.put(name, bundlesMap);
            }
            TreeMap<Long, Object> values = bundlesMap.get(bundle);
            if (values == null) {
                values = new TreeMap<Long, Object>();
                bundlesMap.put(bundle, values);
            }
            values.put(time, value);
            return this;
        }
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.infrastructure.Application#distanceFromRoot(com.blockwithme.meta.types.Bundle)
     */
    @Override
    public int distanceFromRoot(final Bundle bundle) {
        // TODO Auto-generated method stub
        throw new UnsupportedOperationException();
    }
}
