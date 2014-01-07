package com.blockwithme.traits;

import org.eclipse.xtend.lib.Data;
import org.eclipse.xtend.lib.macro.declaration.MutableInterfaceDeclaration;
import org.eclipse.xtend.lib.macro.declaration.TypeReference;
import org.eclipse.xtext.xbase.lib.util.ToStringHelper;

/** A Temp data structure used to store field information */
@Data
@SuppressWarnings("all")
public class FieldInfo {

	private String _name;

	private TypeReference _type;

	private MutableInterfaceDeclaration _interf;

	private String _error;

	private boolean _duplicate;


	public FieldInfo(final String name, final TypeReference type,
			final MutableInterfaceDeclaration interf) {
		this._name = name;
		this._type = type;
		this._interf = interf;
	}


	public String getName() {
		return this._name;
	}


	public TypeReference getType() {
		return this._type;
	}


	public MutableInterfaceDeclaration getInterf() {
		return this._interf;
	}


	public boolean isDuplicate() {
		return this._duplicate;
	}


	public void setDuplicate(boolean _duplicate) {
		this._duplicate = _duplicate;
	}

	public String isError() {
		return this._error;
	}

	public void setError(String _error) {
		this._error = _error;
	}


	@Override
	public int hashCode() {
		final int prime = 31;
		int result = 1;
		result = prime * result + ((_name == null) ? 0 : _name.hashCode());
		result = prime * result + ((_type == null) ? 0 : _type.hashCode());
		result = prime * result + ((_interf == null) ? 0 : _interf.hashCode());
		return result;
	}

	@Override
	public boolean equals(final Object obj) {
		if (this == obj)
			return true;
		if (obj == null)
			return false;
		if (getClass() != obj.getClass())
			return false;
		FieldInfo other = (FieldInfo) obj;
		if (_name == null) {
			if (other._name != null)
				return false;
		} else if (!_name.equals(other._name))
			return false;
		if (_type == null) {
			if (other._type != null)
				return false;
		} else if (!_type.equals(other._type))
			return false;
		if (_interf == null) {
			if (other._interf != null)
				return false;
		} else if (!_interf.equals(other._interf))
			return false;
		return true;
	}

	@Override
	public String toString() {
		String result = new ToStringHelper().toString(this);
		return result;
	}
}
