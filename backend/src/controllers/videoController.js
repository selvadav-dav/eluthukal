const https = require('https');
const http = require('http');
const fs = require('fs');
const path = require('path');
const VideoModel = require('../models/videoModel');
const { successResponse, errorResponse } = require('../utils/apiResponse');
const logger = require('../utils/logger');

/**
 * Stream a remote video file (e.g., from Cloudinary) with HTTP Range support
 */
function streamRemoteVideo(targetUrl, req, res) {
  try {
    const parsedUrl = new URL(targetUrl);
    const client = parsedUrl.protocol === 'http:' ? http : https;

    const requestHeaders = {
      'User-Agent': req.headers['user-agent'] || 'AGARAM-Streamer/1.0',
    };
    if (req.headers.range) {
      requestHeaders['Range'] = req.headers.range;
    }

    const remoteReq = client.get(targetUrl, { headers: requestHeaders }, (remoteRes) => {
      // Follow redirects if any
      if (remoteRes.statusCode >= 300 && remoteRes.statusCode < 400 && remoteRes.headers.location) {
        return streamRemoteVideo(remoteRes.headers.location, req, res);
      }

      const statusCode = remoteRes.statusCode || 200;
      const headersToSend = {
        'Content-Type': remoteRes.headers['content-type'] || 'video/mp4',
        'Accept-Ranges': 'bytes',
        'Cache-Control': 'public, max-age=86400, stale-while-revalidate=604800',
        'X-Content-Type-Options': 'nosniff',
      };

      if (remoteRes.headers['content-length']) {
        headersToSend['Content-Length'] = remoteRes.headers['content-length'];
      }
      if (remoteRes.headers['content-range']) {
        headersToSend['Content-Range'] = remoteRes.headers['content-range'];
      }

      res.writeHead(statusCode, headersToSend);
      remoteRes.pipe(res);

      remoteRes.on('error', (streamErr) => {
        logger.error('Error in remote video stream pipe:', streamErr.message);
        if (!res.headersSent) {
          res.status(500).end();
        }
      });
    });

    remoteReq.on('error', (err) => {
      logger.error('Failed to request remote video stream:', err.message);
      if (!res.headersSent) {
        res.status(502).json({ success: false, message: 'Failed to stream video from media provider' });
      }
    });

    req.on('close', () => {
      remoteReq.destroy();
    });
  } catch (err) {
    logger.error('Invalid streaming URL:', err.message);
    if (!res.headersSent) {
      res.status(400).json({ success: false, message: 'Invalid video URL' });
    }
  }
}

/**
 * Stream a local video file from uploads directory with HTTP Range support
 */
function streamLocalFile(relativePath, req, res) {
  const cleanPath = relativePath.startsWith('/') ? relativePath.slice(1) : relativePath;
  const fullPath = path.resolve(__dirname, '../../', cleanPath);

  if (!fs.existsSync(fullPath)) {
    return res.status(404).json({ success: false, message: 'Local video file not found' });
  }

  const stat = fs.statSync(fullPath);
  const fileSize = stat.size;
  const range = req.headers.range;

  if (range) {
    const parts = range.replace(/bytes=/, '').split('-');
    const start = parseInt(parts[0], 10);
    const end = parts[1] ? parseInt(parts[1], 10) : fileSize - 1;

    if (start >= fileSize) {
      res.status(416).send('Requested range not satisfiable\n' + start + ' >= ' + fileSize);
      return;
    }

    const chunksize = end - start + 1;
    const file = fs.createReadStream(fullPath, { start, end });
    const head = {
      'Content-Range': `bytes ${start}-${end}/${fileSize}`,
      'Accept-Ranges': 'bytes',
      'Content-Length': chunksize,
      'Content-Type': 'video/mp4',
    };
    res.writeHead(206, head);
    file.pipe(res);
  } else {
    const head = {
      'Content-Length': fileSize,
      'Content-Type': 'video/mp4',
      'Accept-Ranges': 'bytes',
    };
    res.writeHead(200, head);
    fs.createReadStream(fullPath).pipe(res);
  }
}

class VideoController {
  static async getAll(req, res, next) {
    try {
      const { category } = req.query;
      const onlyPublished = req.query.all !== 'true';

      const videos = await VideoModel.getAll({ category, onlyPublished });

      const protocol = req.headers['x-forwarded-proto'] || req.protocol;
      const host = req.get('host');
      const baseUrl = `${protocol}://${host}`;

      const enriched = videos.map((v) => ({
        ...v,
        stream_url: `${baseUrl}/api/v1/videos/${v.id}/stream`,
      }));

      return successResponse(res, 'Videos fetched successfully', enriched);
    } catch (error) {
      next(error);
    }
  }

  static async getById(req, res, next) {
    try {
      const video = await VideoModel.getById(req.params.id);
      if (!video) {
        return errorResponse(res, 'Video not found', null, 404);
      }

      const protocol = req.headers['x-forwarded-proto'] || req.protocol;
      const host = req.get('host');
      const stream_url = `${protocol}://${host}/api/v1/videos/${video.id}/stream`;

      return successResponse(res, 'Video fetched successfully', {
        ...video,
        stream_url,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Public: Stream video by DB Video ID (Hides Cloudinary source)
   */
  static async streamById(req, res, next) {
    try {
      const video = await VideoModel.getById(req.params.id);
      if (!video) {
        return errorResponse(res, 'Video not found', null, 404);
      }

      const target = video.video_url || video.local_video_path;
      if (!target) {
        return errorResponse(res, 'Video source not available', null, 404);
      }

      if (target.startsWith('http://') || target.startsWith('https://')) {
        return streamRemoteVideo(target, req, res);
      } else {
        return streamLocalFile(target, req, res);
      }
    } catch (error) {
      next(error);
    }
  }

  /**
   * Public: Proxy stream a video URL query (Hides Cloudinary source)
   */
  static async streamByUrl(req, res, next) {
    try {
      const target = req.query.url;
      if (!target || typeof target !== 'string') {
        return errorResponse(res, 'Video URL parameter required', null, 400);
      }

      if (target.startsWith('http://') || target.startsWith('https://')) {
        return streamRemoteVideo(target, req, res);
      } else {
        return streamLocalFile(target, req, res);
      }
    } catch (error) {
      next(error);
    }
  }

  static async create(req, res, next) {
    try {
      const video = await VideoModel.create(req.body);
      return successResponse(res, 'Video created successfully', video, 201);
    } catch (error) {
      next(error);
    }
  }

  static async update(req, res, next) {
    try {
      const video = await VideoModel.update(req.params.id, req.body);
      if (!video) {
        return errorResponse(res, 'Video not found', null, 404);
      }
      return successResponse(res, 'Video updated successfully', video);
    } catch (error) {
      next(error);
    }
  }

  static async delete(req, res, next) {
    try {
      const deleted = await VideoModel.delete(req.params.id);
      if (!deleted) {
        return errorResponse(res, 'Video not found', null, 404);
      }
      return successResponse(res, 'Video deleted successfully');
    } catch (error) {
      next(error);
    }
  }
}

module.exports = VideoController;

