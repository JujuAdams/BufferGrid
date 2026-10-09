/// GetLooping()
/// Fill()
/// Set()
/// Get()
/// GetInterpolated()
/// Add()
/// SetRegion()
/// AddRegion()
/// Randomize()
/// Duplicate()
/// ConvertToNonLooping()
/// CopyTo()
/// CopyPartToBuffer()
/// CopyBufferToPart()
/// CopyPartTo()
/// Resize()
/// Shift()
/// Serialize()
/// GetBuffer()
/// GetWidth()
/// GetHeight()
/// Destroy()
/// 
/// @param width
/// @param height

function BufferGridFloat32Looping(_width, _height) constructor
{
    static _datatypeSize = __BUFFERGRID_F32_SIZE;
    
    __width  = clamp(_width,  0, 0xFFFF_FFFF);
    __height = clamp(_height, 0, 0xFFFF_FFFF);
    __size   = __BUFFERGRID_F32_SIZE*__width*__height;
    __buffer = buffer_create(__size, buffer_fixed, __BUFFERGRID_F32_SIZE);
    
    static GetDatatypeSize = function()
    {
        return _datatypeSize;
    }
    
    static GetDatatype = function()
    {
        return buffer_u32;
    }
    
    static GetLooping = function()
    {
        return true;
    }
    
    static Fill =  function(_value)
    {
        buffer_fill(__buffer, 0, buffer_f32, _value, __size);
        
        return self;
    }
    
    static Set = function(_x, _y, _value)
    {
        buffer_poke(__buffer, __BUFFERGRID_F32_SIZE*(__BufferGridWrap(_x, __width) + __width*__BufferGridWrap(_y, __height)), buffer_f32, _value);
        return self;
    }
    
    static Get = function(_x, _y)
    {
        return buffer_peek(__buffer, __BUFFERGRID_F32_SIZE*(__BufferGridWrap(_x, __width) + __width*__BufferGridWrap(_y, __height)), buffer_f32);
    }
    
    static GetInterpolated = function(_x, _y)
    {
        var _gridWidth = __width;
        
        var _xFrac = frac(_x);
        var _yFrac = frac(_y);
        _x = floor(_x);
        _y = floor(_y);
        
        var _x0 = __BufferGridWrap(_x,   _gridWidth);
        var _y0 = __BufferGridWrap(_y,   __height);
        var _x1 = __BufferGridWrap(_x+1, _gridWidth);
        var _y1 = __BufferGridWrap(_y+1, __height);
        
        var _buffer = __buffer;
        var _value00 = buffer_peek(_buffer, __BUFFERGRID_F32_SIZE*(_x0 + _gridWidth*_y0), buffer_f32);
        var _value10 = buffer_peek(_buffer, __BUFFERGRID_F32_SIZE*(_x1 + _gridWidth*_y0), buffer_f32);
        var _value01 = buffer_peek(_buffer, __BUFFERGRID_F32_SIZE*(_x0 + _gridWidth*_y1), buffer_f32);
        var _value11 = buffer_peek(_buffer, __BUFFERGRID_F32_SIZE*(_x1 + _gridWidth*_y1), buffer_f32);
        
        return lerp(lerp(_value00, _value10, _xFrac), lerp(_value01, _value11, _xFrac), _yFrac);
    }
    
    static Add = function(_x, _y, _value)
    {
        var _index = __BUFFERGRID_F32_SIZE*(__BufferGridWrap(_x, __width) + __width*__BufferGridWrap(_y, __height));
        buffer_poke(__buffer, _index, buffer_f32, buffer_peek(__buffer, _index, buffer_f32) + _value);
        return self;
    }
    
    static SetRegion = function(_left, _top, _width, _height, _value)
    {
        static _funcSet = function(_buffer, _gridWidth, _left, _top, _width, _height, _value)
        {
            var _size = __BUFFERGRID_F32_SIZE*_width;
            var _index = __BUFFERGRID_F32_SIZE*(_left + _gridWidth*_top);
            repeat(_height)
            {
                buffer_fill(_buffer, _index, buffer_f32, _value, _size);
                _index += __BUFFERGRID_F32_SIZE*_gridWidth;
            }
        }
        
        var _dstBuffer = __buffer;
        var _dstWidth  = __width;
        var _dstHeight = __height;
        
        _left = __BufferGridWrap(_left, _dstWidth);
        _top  = __BufferGridWrap(_top,  _dstHeight);
        var _regionWidth  = min(_dstWidth,  _width);
        var _regionHeight = min(_dstHeight, _height);
        
        if (_left + _regionWidth > _dstWidth)
        {
            if (_top + _regionHeight > _dstHeight)
            {
                //Wrap X + Y
                
                var _firstWidth  = _dstWidth  - _left;
                var _firstHeight = _dstHeight - _top;
                var _remainderX  = _regionWidth  - _firstWidth;
                var _remainderY  = _regionHeight - _firstHeight;
                
                _funcSet(_dstBuffer, _dstWidth, _left, _top, _firstWidth, _firstHeight, _value);
                _funcSet(_dstBuffer, _dstWidth,     0, _top, _remainderX, _firstHeight, _value);
                _funcSet(_dstBuffer, _dstWidth, _left,    0, _firstWidth, _remainderY,  _value);
                _funcSet(_dstBuffer, _dstWidth,     0,    0, _remainderX, _remainderY,  _value);
            }
            else
            {
                //Wrap X
                
                var _firstWidth = _dstWidth  - _left;
                var _remainderX = _regionWidth  - _firstWidth;
                
                _funcSet(_dstBuffer, _dstWidth, _left, _top, _firstWidth, _regionHeight, _value);
                _funcSet(_dstBuffer, _dstWidth,     0, _top, _remainderX, _regionHeight, _value);
            }
        }
        else
        {
            if (_top + _regionHeight > _dstHeight)
            {
                //Wrap Y
                var _firstHeight = _dstHeight - _top;
                var _remainderY  = _regionHeight - _firstHeight;
                
                _funcSet(_dstBuffer, _dstWidth, _left, _top, _regionWidth, _firstHeight, _value);
                _funcSet(_dstBuffer, _dstWidth, _left,    0, _regionWidth, _remainderY,  _value);
            }
            else
            {
                //No wrapping
                _funcSet(_dstBuffer, _dstWidth, _left, _top, _regionWidth, _regionHeight, _value);
            }
        }
        
        return self;
    }
    
    static AddRegion = function(_left, _top, _width, _height, _value)
    {
        static _funcAdd = function(_buffer, _gridWidth, _left, _top, _width, _height, _value)
        {
            var _y = _top;
            repeat(_height)
            {
                var _index = __BUFFERGRID_F32_SIZE*(_left + _gridWidth*_y);
                repeat(_width)
                {
                    buffer_poke(_buffer, _index, buffer_f32, buffer_peek(_buffer, _index, buffer_f32) + _value);
                    _index += __BUFFERGRID_F32_SIZE;
                }
                
                ++_y;
            }
        }
        
        var _dstBuffer = __buffer;
        var _dstWidth  = __width;
        var _dstHeight = __height;
        
        _left = __BufferGridWrap(_left, _dstWidth);
        _top  = __BufferGridWrap(_top,  _dstHeight);
        var _regionWidth  = min(_dstWidth,  _width);
        var _regionHeight = min(_dstHeight, _height);
        
        if (_left + _regionWidth > _dstWidth)
        {
            if (_top + _regionHeight > _dstHeight)
            {
                //Wrap X + Y
                
                var _firstWidth  = _dstWidth  - _left;
                var _firstHeight = _dstHeight - _top;
                var _remainderX  = _regionWidth  - _firstWidth;
                var _remainderY  = _regionHeight - _firstHeight;
                
                _funcAdd(_dstBuffer, _dstWidth, _left, _top, _firstWidth, _firstHeight, _value);
                _funcAdd(_dstBuffer, _dstWidth,     0, _top, _remainderX, _firstHeight, _value);
                _funcAdd(_dstBuffer, _dstWidth, _left,    0, _firstWidth, _remainderY,  _value);
                _funcAdd(_dstBuffer, _dstWidth,     0,    0, _remainderX, _remainderY,  _value);
            }
            else
            {
                //Wrap X
                
                var _firstWidth = _dstWidth  - _left;
                var _remainderX = _regionWidth  - _firstWidth;
                
                _funcAdd(_dstBuffer, _dstWidth, _left, _top, _firstWidth, _regionHeight, _value);
                _funcAdd(_dstBuffer, _dstWidth,     0, _top, _remainderX, _regionHeight, _value);
            }
        }
        else
        {
            if (_top + _regionHeight > _dstHeight)
            {
                //Wrap Y
                var _firstHeight = _dstHeight - _top;
                var _remainderY  = _regionHeight - _firstHeight;
                
                _funcAdd(_dstBuffer, _dstWidth, _left, _top, _regionWidth, _firstHeight, _value);
                _funcAdd(_dstBuffer, _dstWidth, _left,    0, _regionWidth, _remainderY,  _value);
            }
            else
            {
                //No wrapping
                _funcAdd(_dstBuffer, _dstWidth, _left, _top, _regionWidth, _regionHeight, _value);
            }
        }
        
        return self;
    }
    
    static Randomize = function(_min, _max)
    {
        var _buffer = __buffer;
        
        buffer_seek(_buffer, buffer_seek_start, 0);
        repeat(__width*__height)
        {
            buffer_write(_buffer, buffer_f32, random_range(_min, _max));
        }
    }
    
    static Duplicate = function()
    {
        var _new = new BufferGridFloat32(__width, __height);
        buffer_copy(__buffer, 0, __size, _new.__buffer, 0);
        return _new;
    }
    
    static ConvertToNonLooping = function()
    {
        var _new = new BufferGridFloat32(__width, __height);
        buffer_copy(__buffer, 0, __size, _new.__buffer, 0);
        Destroy();
        return _new;
    }
    
    static CopyTo = function(_dstBufferGrid)
    {
        if (__size != _dstBufferGrid.__size)
        {
            __BufferGridError("Buffer size mismatch");
            return;
        }
        
        buffer_copy(__buffer, 0, __size, _dstBufferGrid.__buffer, 0);
        return self;
    }
    
    static CopyPartToBuffer = function(_srcLeft, _srcTop, _copyWidth, _copyHeight, _dstBuffer, _dstOffset)
    {
        var _srcBuffer = __buffer;
        var _srcWidth  = __width;
        var _srcHeight = __height;
        
        var _dstWidth = _copyWidth; //Presume the width of the destination buffer is equal to the copy width
        
        _srcLeft = __BufferGridWrap(_srcLeft, _srcWidth);
        _srcTop  = __BufferGridWrap(_srcTop,  _srcHeight);
        
        var _dstY = 0;
        var _srcY = _srcTop;
        var _remainingY = _copyHeight;
        while(_remainingY > 0)
        {
            var _availableHeight = min(_remainingY, _srcHeight - _srcY);
            
            var _dstX = 0;
            var _srcX = _srcLeft;
            var _remainingX = _copyWidth;
            while(_remainingX > 0)
            {
                var _availableWidth = min(_remainingX, _srcWidth - _srcX);
                
                buffer_copy_stride(_srcBuffer, __BUFFERGRID_F32_SIZE*(_srcX + _srcWidth*_srcY), __BUFFERGRID_F32_SIZE*_availableWidth, __BUFFERGRID_F32_SIZE*_srcWidth, _availableHeight,
                                   _dstBuffer, __BUFFERGRID_F32_SIZE*(_dstX + _dstWidth*_dstY) + _dstOffset, __BUFFERGRID_F32_SIZE*_dstWidth);
                
                _dstX += _availableWidth;
                _remainingX -=_availableWidth;
                _srcX = __BufferGridWrap(_srcX + _availableWidth, _srcWidth);
            }
            
            _dstY += _availableHeight;
            _remainingY -=_availableHeight;
            _srcY = __BufferGridWrap(_srcY + _availableHeight, _srcHeight);
        }
        
        return self;
    }
    
    static CopyBufferToPart = function(_srcBuffer, _srcOffset, _inCopyWidth, _inCopyHeight, _dstLeft, _dstTop)
    {
        var _dstBuffer = __buffer;
        var _dstWidth  = __width;
        var _dstHeight = __height;
        
        _dstLeft = __BufferGridWrap(_dstLeft, _dstWidth);
        _dstTop  = __BufferGridWrap(_dstTop,  _dstHeight);
        
        var _copyWidth  = min(_dstWidth,  _inCopyWidth);
        var _copyHeight = min(_dstHeight, _inCopyHeight);
        
        if (_dstLeft + _copyWidth > _dstWidth)
        {
            if (_dstTop + _copyHeight > _dstHeight)
            {
                //Wrap X + Y
                
                var _firstWidth  = _dstWidth - _dstLeft;
                var _firstHeight = _dstHeight - _dstTop;
                var _remainderX  = _copyHeight - _firstWidth;
                var _remainderY  = _copyHeight - _firstHeight;
                
                buffer_copy_stride(_srcBuffer, _srcOffset, __BUFFERGRID_F32_SIZE*_firstWidth, __BUFFERGRID_F32_SIZE*_inCopyWidth, _firstHeight,
                                   _dstBuffer, __BUFFERGRID_F32_SIZE*(_dstLeft + _dstWidth*_dstTop), __BUFFERGRID_F32_SIZE*_dstWidth);
                
                buffer_copy_stride(_srcBuffer, _srcOffset + __BUFFERGRID_F32_SIZE*_firstWidth, __BUFFERGRID_F32_SIZE*_remainderX, __BUFFERGRID_F32_SIZE*_inCopyWidth, _firstHeight,
                                   _dstBuffer, __BUFFERGRID_F32_SIZE*_dstWidth*_dstTop, __BUFFERGRID_F32_SIZE*_dstWidth);
                
                buffer_copy_stride(_srcBuffer, _srcOffset + __BUFFERGRID_F32_SIZE*_inCopyWidth*_firstHeight, __BUFFERGRID_F32_SIZE*_firstWidth, __BUFFERGRID_F32_SIZE*_inCopyWidth, _remainderY,
                                   _dstBuffer, __BUFFERGRID_F32_SIZE*_dstLeft, __BUFFERGRID_F32_SIZE*_dstWidth);
                
                buffer_copy_stride(_srcBuffer, _srcOffset + __BUFFERGRID_F32_SIZE*(_firstWidth + _inCopyWidth*_firstHeight), __BUFFERGRID_F32_SIZE*_remainderX, __BUFFERGRID_F32_SIZE*_inCopyWidth, _remainderY,
                                   _dstBuffer, 0, __BUFFERGRID_F32_SIZE*_dstWidth);
            }
            else
            {
                //Wrap X
                
                var _firstWidth = _dstWidth - _dstLeft;
                var _remainderX = _copyHeight - _firstWidth;
                
                buffer_copy_stride(_srcBuffer, _srcOffset, __BUFFERGRID_F32_SIZE*_firstWidth, __BUFFERGRID_F32_SIZE*_inCopyWidth, _copyHeight,
                                   _dstBuffer, __BUFFERGRID_F32_SIZE*(_dstLeft + _dstWidth*_dstTop), __BUFFERGRID_F32_SIZE*_dstWidth);
                
                buffer_copy_stride(_srcBuffer, _srcOffset + __BUFFERGRID_F32_SIZE*_firstWidth, __BUFFERGRID_F32_SIZE*_remainderX, __BUFFERGRID_F32_SIZE*_inCopyWidth, _copyHeight,
                                   _dstBuffer, __BUFFERGRID_F32_SIZE*_dstWidth*_dstTop, __BUFFERGRID_F32_SIZE*_dstWidth);
            }
        }
        else
        {
            if (_dstTop + _copyHeight > _dstHeight)
            {
                //Wrap Y
                
                var _firstHeight = _dstHeight - _dstTop;
                var _remainderY = _copyHeight - _firstHeight;
                
                buffer_copy_stride(_srcBuffer, _srcOffset, __BUFFERGRID_F32_SIZE*_copyWidth, __BUFFERGRID_F32_SIZE*_inCopyWidth, _firstHeight,
                                   _dstBuffer, __BUFFERGRID_F32_SIZE*(_dstLeft + _dstWidth*_dstTop), __BUFFERGRID_F32_SIZE*_dstWidth);
                
                buffer_copy_stride(_srcBuffer, _srcOffset + __BUFFERGRID_F32_SIZE*_inCopyWidth*_firstHeight, __BUFFERGRID_F32_SIZE*_copyWidth, __BUFFERGRID_F32_SIZE*_inCopyWidth, _remainderY,
                                   _dstBuffer, __BUFFERGRID_F32_SIZE*_dstLeft, __BUFFERGRID_F32_SIZE*_dstWidth);
            }
            else
            {
                //No wrapping
                buffer_copy_stride(_srcBuffer, _srcOffset, __BUFFERGRID_F32_SIZE*_copyWidth, __BUFFERGRID_F32_SIZE*_inCopyWidth, _copyHeight,
                                   _dstBuffer, __BUFFERGRID_F32_SIZE*(_dstLeft + _dstWidth*_dstTop), __BUFFERGRID_F32_SIZE*_dstWidth);
            }
        }
        
        return self;
    }
    
    static CopyPartTo = function(_srcLeft, _srcTop, _copyWidth, _copyHeight, _dstBufferGrid, _dstLeft, _dstTop)
    {
        if (_datatypeSize != _dstBufferGrid._datatypeSize)
        {
            __BufferGridError($"Datatype size mismatch (source {_datatypeSize} vs. destination {_dstBufferGrid._datatypeSize})");
            return;
        }
        
        var _srcWidth  = __width;
        var _srcHeight = __height;
        var _dstWidth  = _dstBufferGrid.__width;
        var _dstHeight = _dstBufferGrid.__height;
        
        if ((_srcLeft >= _srcWidth) || (_srcLeft >= _srcHeight) || (_dstLeft >= _dstWidth) || (_dstTop >= _dstHeight))
        {
            return;
        }
        
        var _srcRight  = _srcLeft + _copyWidth-1;
        var _srcBottom = _srcTop + _copyHeight-1;
        
        if ((_srcRight < 0) || (_srcBottom < 0))
        {
            return;
        }
        
        _copyWidth  = min(_copyWidth,  _srcWidth,  _dstWidth);
        _copyHeight = min(_copyHeight, _srcHeight, _dstHeight);
        
        var _dstRight  = _dstLeft + _copyWidth-1;
        var _dstBottom = _dstTop + _copyHeight-1;
        
        if ((_dstRight < 0) || (_dstBottom < 0))
        {
            return;
        }
        
        //Copy to an intermediate buffer because dealing with two looping buffers is too much for my brain
        var _workBuffer = buffer_create(__BUFFERGRID_F32_SIZE*_copyWidth*_copyHeight, buffer_fixed, __BUFFERGRID_F32_SIZE);
        
        CopyPartToBuffer(_srcLeft, _srcTop, _copyWidth, _copyHeight, _workBuffer, 0);
        _dstBufferGrid.CopyBufferToPart(_workBuffer, 0, _dstLeft, _dstTop, _copyWidth, _copyHeight);
        
        buffer_delete(_workBuffer);
        
        return self;
    }
    
    static Resize = function(_newWidth, _newHeight, _hAlign = fa_left, _vAlign = fa_top)
    {
        _newWidth  = clamp(_newWidth,  0, 0xFFFF_FFFF);
        _newHeight = clamp(_newHeight, 0, 0xFFFF_FFFF);
        
        var _oldWidth  = __width;
        var _oldHeight = __height;
        
        if ((_oldWidth == _newWidth) && (_oldHeight == _newHeight)) return;
        
        var _old = __buffer;
        var _new = buffer_create(__BUFFERGRID_F32_SIZE*_newWidth*_newHeight, buffer_fixed, __BUFFERGRID_F32_SIZE);
        
        if ((_newWidth > 0) && (_newHeight > 0))
        {
            var _copyWidth  = min(_oldWidth, _newWidth);
            var _copyHeight = min(_oldHeight, _newHeight);
            
            var _srcX = 0;
            var _srcY = 0;
            var _dstX = 0;
            var _dstY = 0;
            
            if (_hAlign == fa_center)
            {
                if (_newWidth > _oldWidth)
                {
                    _dstX = floor(_newWidth - _oldWidth)/2;
                }
                else
                {
                    _srcX = floor(_oldWidth - _newWidth)/2;
                }
            }
            else if (_hAlign == fa_right)
            {
                if (_newWidth > _oldWidth)
                {
                    _dstX = _newWidth - _oldWidth;
                }
                else
                {
                    _srcX = _oldWidth - _newWidth;
                }
            }
            
            if (_vAlign == fa_center)
            {
                if (_newHeight > _oldHeight)
                {
                    _dstY = floor(_newHeight - _oldHeight)/2;
                }
                else
                {
                    _srcY = floor(_oldHeight - _newHeight)/2;
                }
            }
            else if (_vAlign == fa_right)
            {
                if (_newHeight > _oldHeight)
                {
                    _dstY = _newHeight - _oldHeight;
                }
                else
                {
                    _srcY = _oldHeight - _newHeight;
                }
            }
            
            buffer_copy_stride(_old, __BUFFERGRID_F32_SIZE*(_srcX + _oldWidth*_srcY), __BUFFERGRID_F32_SIZE*_copyWidth, __BUFFERGRID_F32_SIZE*_oldWidth, _copyHeight,
                               _new, __BUFFERGRID_F32_SIZE*(_dstX + _newWidth*_dstY), __BUFFERGRID_F32_SIZE*_newWidth);
        }
        
        buffer_delete(_old);
        __width  = _newWidth;
        __height = _newHeight;
        __size   = __BUFFERGRID_F32_SIZE*_newWidth*_newHeight;
        __buffer = _new;
        
        return self;
    }
    
    static Shift = function(_dX, _dY)
    {
        var _width  = __width;
        var _height = __height;
        
        _dX = __BufferGridWrap(_dX, _width);
        _dY = __BufferGridWrap(_dY, _height);
        
        if ((_dX == 0) && (_dY == 0)) return;
        
        var _old = __buffer;
        var _new = buffer_create(__BUFFERGRID_F32_SIZE*_width*_height, buffer_fixed, __BUFFERGRID_F32_SIZE);
        
        if (_dX == 0)
        {
            //Y only
            var _remainder = _height - _dY;
            
            //Copy top to middle
            buffer_copy(_old, 0, __BUFFERGRID_F32_SIZE*_width*_remainder, _new, __BUFFERGRID_F32_SIZE*_width*_dY);
            
            //Copy bottom to top
            buffer_copy(_old, __BUFFERGRID_F32_SIZE*_width*_remainder, __BUFFERGRID_F32_SIZE*_width*_dY, _new, 0);
        }
        else if (_dY == 0)
        {
            //X only
            var _remainder = _width - _dX;
            
            //Copy left to middle
            buffer_copy_stride(_old, 0, __BUFFERGRID_F32_SIZE*_remainder, __BUFFERGRID_F32_SIZE*_width, _height,
                               _new, __BUFFERGRID_F32_SIZE*_dX, __BUFFERGRID_F32_SIZE*_width);
            
            //Copy right to left
            buffer_copy_stride(_old, __BUFFERGRID_F32_SIZE*_remainder, __BUFFERGRID_F32_SIZE*_dX, __BUFFERGRID_F32_SIZE*_width, _height,
                               _new, 0, __BUFFERGRID_F32_SIZE*_width);
        }
        else
        {
            //X and Y
            var _remainderX = _width  - _dX;
            var _remainderY = _height - _dY;
            
            //Copy top-left to middle
            buffer_copy_stride(_old, 0, __BUFFERGRID_F32_SIZE*_remainderX, __BUFFERGRID_F32_SIZE*_width, _remainderY,
                               _new, __BUFFERGRID_F32_SIZE*(_dX + _width*_dY), __BUFFERGRID_F32_SIZE*_width);
            
            //Copy right to left
            buffer_copy_stride(_old, __BUFFERGRID_F32_SIZE*_remainderX, __BUFFERGRID_F32_SIZE*_dX, __BUFFERGRID_F32_SIZE*_width, _remainderY,
                               _new, __BUFFERGRID_F32_SIZE*_width*_dY, __BUFFERGRID_F32_SIZE*_width);
            
            //Copy bottom to top
            buffer_copy_stride(_old, __BUFFERGRID_F32_SIZE*_width*_remainderY, __BUFFERGRID_F32_SIZE*_remainderX, __BUFFERGRID_F32_SIZE*_width, _dY,
                               _new, __BUFFERGRID_F32_SIZE*_dX, __BUFFERGRID_F32_SIZE*_width);
            
            //Copy bottom-right to top-left
            buffer_copy_stride(_old, __BUFFERGRID_F32_SIZE*(_remainderX + _width*_remainderY), __BUFFERGRID_F32_SIZE*_dX, __BUFFERGRID_F32_SIZE*_width, _dY,
                               _new, 0, __BUFFERGRID_F32_SIZE*_width);
        }
        
        buffer_delete(_old);
        __buffer = _new;
        
        return self;
    }
    
    static Serialize = function(_buffer)
    {
        buffer_write(_buffer, buffer_u8, 0x01);
        buffer_write(_buffer, buffer_bool, true); //looping
        buffer_write(_buffer, buffer_u32, __width);
        buffer_write(_buffer, buffer_u32, __height);
        
        if (buffer_tell(_buffer) + __size > buffer_get_size(_buffer))
        {
            buffer_resize(_buffer, buffer_tell(_buffer) + __size);
        }
        
        buffer_copy(__buffer, 0, __size, _buffer, buffer_tell(_buffer));
        buffer_seek(_buffer, buffer_seek_relative, __size);
        
        return self;
    }
    
    static __Deserialize = function(_buffer)
    {
        buffer_copy(_buffer, buffer_tell(_buffer), __size, __buffer, 0);
        buffer_seek(_buffer, buffer_seek_relative, __size);
        
        return self;
    }
    
    static GetBuffer = function()
    {
        return __buffer;
    }
    
    static GetWidth = function()
    {
        return __width;
    }
    
    static GetHeight = function()
    {
        return __height;
    }
    
    static Destroy = function()
    {
        buffer_delete(__buffer);
    }
}