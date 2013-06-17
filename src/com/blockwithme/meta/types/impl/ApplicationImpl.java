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
package com.blockwithme.meta.types.impl;

import java.util.Comparator;
import java.util.Objects;

import com.blockwithme.meta.Dynamic;
import com.blockwithme.meta.infrastructure.Connection;
import com.blockwithme.meta.infrastructure.Connector;
import com.blockwithme.meta.types.ActorRef;
import com.blockwithme.meta.types.Application;
import com.blockwithme.meta.types.Bundle;
import com.blockwithme.properties.impl.RootImpl;

/**
 * @author monster
 *
 */
public class ApplicationImpl extends RootImpl<Long> implements Application {

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

    /** The bundle. */
    private volatile Bundle bundle;

    /**
     * @param parent
     * @param localKey
     * @param when
     */
    protected ApplicationImpl(final boolean javaApp, final boolean distributed,
            final Long when) {
        super(when);
        this.javaApp = javaApp;
        this.distributed = distributed;
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.Configurable#app()
     */
    @Override
    public Application app() {
        return this;
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
     * @see com.blockwithme.meta.infrastructure.Application#distanceFromRoot(com.blockwithme.meta.types.Bundle)
     */
    @Override
    public int distanceFromRoot(final Bundle bundle) {
        // TODO Auto-generated method stub
        throw new UnsupportedOperationException();
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.infrastructure.AppState#connectors()
     */
    @Override
    public Connector[] connectors() {
        return listChildValues("connectors", Connector.class, false);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.infrastructure.AppState#findConnector(java.lang.String)
     */
    @Override
    public Connector findConnector(final String name) {
        return find("connectors" + SEPATATOR + name, Connector.class);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.infrastructure.AppState#connections()
     */
    @Override
    @Dynamic
    public Connection[] connections() {
        return listChildValues("connections", Connection.class, false);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.infrastructure.AppState#actors()
     */
    @Override
    @Dynamic
    public ActorRef[] actors() {
        return listChildValues("actors", ActorRef.class, false);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.Definition#name()
     */
    @Override
    public String name() {
        return localKey();
    }

    /* (non-Javadoc)
     * @see java.lang.Comparable#compareTo(java.lang.Object)
     */
    @Override
    public int compareTo(final Application o) {
        return name().compareTo(o.name());
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.infrastructure.Application#bundles()
     */
    @Override
    @Dynamic
    public Bundle[] bundles() {
        return listChildValues("bundles", Bundle.class, false);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.infrastructure.Application#findBundle(java.lang.String)
     */
    @Override
    public Bundle findBundle(final String name) {
        return find("bundles" + SEPATATOR + name, Bundle.class);
    }
}
